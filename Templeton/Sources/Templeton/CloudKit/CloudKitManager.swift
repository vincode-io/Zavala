//
//  CloudKitManager.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import UIKit
import os.log
import SystemConfiguration
import CloudKit
import RSCore

public extension Notification.Name {
	static let CloudKitSyncDidComplete = Notification.Name(rawValue: "CloudKitSyncDidComplete")
}

public class CloudKitManager {

	var modifications = [CKRecordZone.ID: ([CKRecord], [CKRecord.ID])]()

	class CombinedRequest {
		var documentRequest: CloudKitActionRequest?
		var rowRequests = [CloudKitActionRequest]()
		var imageRequests = [CloudKitActionRequest]()
	}

	let defaultZone: CloudKitOutlineZone
	var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "CloudKit")

	var isSyncAvailable: Bool {
		return !isSyncing && isNetworkAvailable
	}
	
	private let container: CKContainer = {
		let orgID = Bundle.main.object(forInfoDictionaryKey: "OrganizationIdentifier") as! String
		return CKContainer(identifier: "iCloud.\(orgID).Zavala")
	}()

	private weak var errorHandler: ErrorHandler?
	private weak var account: Account?

	private let requestsFileQueue = DispatchQueue(label: "Requests File Queue")
	private var writeRequestsBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
	private var sendChangesBackgroundTaskID = UIBackgroundTaskIdentifier.invalid

	private var coalescingQueue = CoalescingQueue(name: "Send Modifications", interval: 5)
	private var zones = [CKRecordZone.ID: CloudKitOutlineZone]()

	private var isSyncing = false
	private var isNetworkAvailable: Bool {
		var zeroAddress = sockaddr_in()
		zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
		zeroAddress.sin_family = sa_family_t(AF_INET)

		guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
			 $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
				 SCNetworkReachabilityCreateWithAddress(nil, $0)
			 }
		 }) else {
			 return false
		 }

		 var flags: SCNetworkReachabilityFlags = []
		 if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
			 return false
		 }

		 let isReachable = flags.contains(.reachable)
		 let needsConnection = flags.contains(.connectionRequired)

		 return (isReachable && !needsConnection)
	}
		
	init(account: Account, errorHandler: ErrorHandler) {
		self.account = account
		self.defaultZone = CloudKitOutlineZone(container: container)
		defaultZone.delegate = CloudKitAcountZoneDelegate(account: account, zoneID: self.defaultZone.zoneID)
		self.zones[defaultZone.zoneID] = defaultZone
		self.errorHandler = errorHandler
	}
	
	func firstTimeSetup() {
		defaultZone.fetchZoneRecord {  [weak self] result in
			switch result {
			case .success:
				self?.defaultZone.subscribeToZoneChanges()
			case .failure(let error):
				self?.presentError(error)
			}
		}
		subscribeToSharedDatabaseChanges()
	}
	
	func addRequest(_ request: CloudKitActionRequest) {
		var requests = Set<CloudKitActionRequest>()
		requests.insert(request)
		addRequests(requests)
	}
	
	func addRequests(_ requests: Set<CloudKitActionRequest>) {
		let completeProcessing = { [unowned self] in
			UIApplication.shared.endBackgroundTask(self.writeRequestsBackgroundTaskID)
			self.writeRequestsBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
		}

		self.writeRequestsBackgroundTaskID = UIApplication.shared.beginBackgroundTask {
			completeProcessing()
			os_log("CloudKit add requests terminated for running too long.", log: self.log, type: .info)
		}
		
		requestsFileQueue.async {
			self.writerRequests(requests)
			DispatchQueue.main.async {
				self.coalescingQueue.add(self, #selector(self.sendQueuedChanges))
				completeProcessing()
			}
		}
	}
	
	func receiveRemoteNotification(userInfo: [AnyHashable : Any], completion: @escaping (() -> Void)) {
		if let zoneNote = CKRecordZoneNotification(fromRemoteNotificationDictionary: userInfo), zoneNote.notificationType == .recordZone {
			guard let zoneId = zoneNote.databaseScope == .private ? defaultZone.zoneID : zoneNote.recordZoneID else {
				completion()
				return
			}
			fetchChanges(zoneID: zoneId, completion: completion)
		}
		
		if let dbNote = CKDatabaseNotification(fromRemoteNotificationDictionary: userInfo), dbNote.notificationType == .database {
			fetchAllChanges()
		}
	}
	
	func findZone(zoneID: CKRecordZone.ID) -> CloudKitOutlineZone {
		if let zone = zones[zoneID] {
			return zone
		}
		
		let zone = CloudKitOutlineZone(container: container, database: container.sharedCloudDatabase, zoneID: zoneID)
		zone.delegate = CloudKitAcountZoneDelegate(account: account!, zoneID: zoneID)
		zones[zoneID] = zone
		return zone
	}
	
	func sync(completion: (() -> Void)? = nil) {
		guard isNetworkAvailable else {
			completion?()
			return
		}
		
		sendChanges() {
			self.fetchAllChanges() {
				NotificationCenter.default.post(name: .CloudKitSyncDidComplete, object: self, userInfo: nil)
				completion?()
			}
		}
	}
	
	func userDidAcceptCloudKitShareWith(_ shareMetadata: CKShare.Metadata) {
		let op = CKAcceptSharesOperation(shareMetadatas: [shareMetadata])
		op.qualityOfService = CloudKitOutlineZone.qualityOfService
		
		op.acceptSharesCompletionBlock = { [weak self] error in
			
			guard let self = self else { return }
			
			switch CloudKitZoneResult.resolve(error) {
			case .success:
				let zoneID = shareMetadata.share.recordID.zoneID
				self.fetchChanges(zoneID: zoneID)
			default:
				DispatchQueue.main.async {
					self.presentError(error!)
				}
			}
		}
		
		container.add(op)
	}
	
	func prepareCloudSharingController(document: Document, completion: @escaping (Result<UICloudSharingController, Error>) -> Void) {
		guard let zoneID = document.zoneID else {
			completion(.failure(CloudKitOutlineZoneError.unknown))
			return
		}
		
		let zone = findZone(zoneID: zoneID)
		if document.isCollaborating {
			zone.prepareSharedCloudSharingController(document: document, completion: completion)
		} else {
			zone.prepareNewCloudSharingController(document: document, completion: completion)
		}
	}

	func resume() {
		sync()
	}
	
	func suspend() {
		coalescingQueue.performCallsImmediately()
	}
	
	func accountDidDelete(account: Account) {
		var zoneIDs = Set<CKRecordZone.ID>()

		// If the user deletes all the documents prior to deleting the account, we
		// won't reset the default zone unless we add it manually.
		zoneIDs.insert(defaultZone.zoneID)
		
		for doc in account.documents ?? [Document]() {
			if let zoneID = doc.zoneID {
				zoneIDs.insert(zoneID)
			}
		}
		
		for zoneID in zoneIDs {
			findZone(zoneID: zoneID).resetChangeToken()
		}
		
		sharedDatabaseChangeToken = nil
	}
	
}

extension CloudKitManager {
	
	private func presentError(_ error: Error) {
		errorHandler?.presentError(error, title: "CloudKit Syncing Error")
	}

	private func writerRequests(_ requests: Set<CloudKitActionRequest>) {
		let queuedRequests: Set<CloudKitActionRequest>
		if let fileData = try? Data(contentsOf: CloudKitActionRequest.actionRequestFile) {
			let decoder = PropertyListDecoder()
			if let decodedRequests = try? decoder.decode(Set<CloudKitActionRequest>.self, from: fileData) {
				queuedRequests = decodedRequests
			} else {
				queuedRequests = Set<CloudKitActionRequest>()
			}
		} else {
			queuedRequests = Set<CloudKitActionRequest>()
		}

		let mergedRequests = queuedRequests.union(requests)
		
		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		if let encodedIDs = try? encoder.encode(mergedRequests) {
			try? encodedIDs.write(to: CloudKitActionRequest.actionRequestFile)
		}
	}
	
	@objc private func sendQueuedChanges() {
		guard isNetworkAvailable else {
			return
		}
		sendChanges() {
			self.fetchAllChanges()
		}
	}

	private func sendChanges(completion: @escaping (() -> Void)) {
		isSyncing = true

		let completeProcessing = { [unowned self] in
			self.modifications = [CKRecordZone.ID: ([CKRecord], [CKRecord.ID])]()
			self.isSyncing = false
			
			UIApplication.shared.endBackgroundTask(self.sendChangesBackgroundTaskID)
			self.sendChangesBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
			
			completion()
		}

		self.sendChangesBackgroundTaskID = UIApplication.shared.beginBackgroundTask {
			completeProcessing()
			os_log("CloudKit sync processing terminated for running too long.", log: self.log, type: .info)
		}
		
		requestsFileQueue.async {
			let combinedRequests = self.loadRequests()
			DispatchQueue.main.async {
				self.send(combinedRequests: combinedRequests) {
					completeProcessing()
				}
			}
		}
	}
	
	private func loadRequests() -> [String: CombinedRequest] {
		var combinedRequests = [String: CombinedRequest]()

		guard let queuedRequests = CloudKitActionRequest.loadRequests(), !queuedRequests.isEmpty else { return combinedRequests }
		
		for queuedRequest in queuedRequests {
			switch queuedRequest.id {
			case .document(_, let documentUUID):
				if let combinedRequest = combinedRequests[documentUUID] {
					combinedRequest.documentRequest = queuedRequest
					combinedRequests[documentUUID] = combinedRequest
				} else {
					let combinedRequest = CombinedRequest()
					combinedRequest.documentRequest = queuedRequest
					combinedRequests[documentUUID] = combinedRequest
				}
			case .row(_, let documentUUID, _):
				if let combinedRequest = combinedRequests[documentUUID] {
					combinedRequest.rowRequests.append(queuedRequest)
					combinedRequests[documentUUID] = combinedRequest
				} else {
					let combinedRequest = CombinedRequest()
					combinedRequest.rowRequests.append(queuedRequest)
					combinedRequests[documentUUID] = combinedRequest
				}
			case .image(_, let documentUUID, _, _):
				if let combinedRequest = combinedRequests[documentUUID] {
					combinedRequest.imageRequests.append(queuedRequest)
					combinedRequests[documentUUID] = combinedRequest
				} else {
					let combinedRequest = CombinedRequest()
					combinedRequest.imageRequests.append(queuedRequest)
					combinedRequests[documentUUID] = combinedRequest
				}
			default:
				fatalError()
			}
		}
		
		return combinedRequests
	}
	

	private func send(combinedRequests: [String : CloudKitManager.CombinedRequest], completion: @escaping (() -> Void)) {
		guard !combinedRequests.isEmpty,
			  let account = AccountManager.shared.cloudKitAccount,
			  let cloudKitManager = account.cloudKitManager else {
			completion()
			return
		}
		
		var loadedDocuments = [Document]()
		var tempFileURLs = [URL]()

		for documentUUID in combinedRequests.keys {
			guard let combinedRequest = combinedRequests[documentUUID] else { continue }
			
			// If we don't have a document, we probably have a delete request to send.
			// We don't have to continue processing since we cascade delete our rows.
			guard let document = account.findDocument(documentUUID: documentUUID) else {
				if let docRequest = combinedRequest.documentRequest {
					addDelete(docRequest)
				}
				continue
			}
			
			document.load()
			loadedDocuments.append(document)
			
			// This has to be a save for the document
			if combinedRequest.documentRequest != nil {
				addSave(document)
			}

			guard let outline = document.outline, let zoneID = outline.zoneID else { continue }
			let outlineRecordID = CKRecord.ID(recordName: outline.id.description, zoneID: zoneID)
			
			// Now process all the rows
			for imageRequest in combinedRequest.rowRequests {
				if let row = outline.findRow(id: imageRequest.id.rowUUID) {
					addSave(zoneID: zoneID, outlineRecordID: outlineRecordID, row: row)
				} else {
					addDelete(imageRequest)
				}
			}
			
			// Now process all the images
			for imageRequest in combinedRequest.imageRequests {
				// if the row is gone, we don't need to process the images because we cascade our deletes
				if let row = outline.findRow(id: imageRequest.id.rowUUID) {
					if let image = row.findImage(id: imageRequest.id) {
						let tempFileURL = addSave(zoneID: zoneID, image: image)
						tempFileURLs.append(tempFileURL)
					} else {
						addDelete(imageRequest)
					}
				}
			}
		}
		
		// Send the grouped changes
		
		var groupError: Error? = nil
		let group = DispatchGroup()
		
		for zoneID in modifications.keys {
			group.enter()

			let cloudKitZone = cloudKitManager.findZone(zoneID: zoneID)
			let (saves, deletes) = modifications[zoneID]!

			cloudKitZone.modify(recordsToSave: saves, recordIDsToDelete: deletes) { result in
				if case .failure(let error) = result {
					groupError = error
				}
				group.leave()
			}
		}
		
		group.notify(queue: DispatchQueue.main) {
			loadedDocuments.forEach { $0.unload() }
			if let groupError = groupError {
				self.presentError(groupError)
			} else {
				self.deleteRequests()
				self.deleteTempFiles(tempFileURLs)
			}
			completion()
		}
	}
	
	private func deleteRequests() {
		try? FileManager.default.removeItem(at: CloudKitActionRequest.actionRequestFile)
	}
	
	private func deleteTempFiles(_ urls: [URL]) {
		for url in urls {
			try? FileManager.default.removeItem(at: url)
		}
	}
	
	private func addSave(_ document: Document) {
		guard let outline = document.outline, let zoneID = outline.zoneID else { return }
		
		outline.syncID = UUID().uuidString
		
		let recordID = CKRecord.ID(recordName: outline.id.description, zoneID: zoneID)
		let record = CKRecord(recordType: CloudKitOutlineZone.CloudKitOutline.recordType, recordID: recordID)
		
		record[CloudKitOutlineZone.CloudKitOutline.Fields.syncID] = outline.syncID
		record[CloudKitOutlineZone.CloudKitOutline.Fields.title] = outline.title
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerName] = outline.ownerName
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerEmail] = outline.ownerEmail
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerURL] = outline.ownerURL
		record[CloudKitOutlineZone.CloudKitOutline.Fields.created] = outline.created
		record[CloudKitOutlineZone.CloudKitOutline.Fields.updated] = outline.updated
		record[CloudKitOutlineZone.CloudKitOutline.Fields.tagNames] = outline.tags.map { $0.name }
		if let rowOrder = outline.rowOrder {
			record[CloudKitOutlineZone.CloudKitOutline.Fields.rowOrder] = Array(rowOrder)
		}
		record[CloudKitOutlineZone.CloudKitOutline.Fields.documentLinks] = outline.documentLinks?.map { $0.description }
		record[CloudKitOutlineZone.CloudKitOutline.Fields.documentBacklinks] = outline.documentBacklinks?.map { $0.description }
		record[CloudKitOutlineZone.CloudKitOutline.Fields.hasAltLinks] = outline.hasAltLinks
		record[CloudKitOutlineZone.CloudKitOutline.Fields.disambiguator] = outline.disambiguator

		addSave(zoneID, record)
	}
	
	private func addSave(zoneID: CKRecordZone.ID, outlineRecordID: CKRecord.ID, row: Row) {
		row.syncID = UUID().uuidString
		
		let recordID = CKRecord.ID(recordName: row.entityID.description, zoneID: zoneID)
		let record = CKRecord(recordType: CloudKitOutlineZone.CloudKitRow.recordType, recordID: recordID)
		
		record.parent = CKRecord.Reference(recordID: outlineRecordID, action: .none)
		record[CloudKitOutlineZone.CloudKitRow.Fields.outline] = CKRecord.Reference(recordID: outlineRecordID, action: .deleteSelf)
		record[CloudKitOutlineZone.CloudKitRow.Fields.syncID] = row.syncID
		record[CloudKitOutlineZone.CloudKitRow.Fields.subtype] = "text"
		record[CloudKitOutlineZone.CloudKitRow.Fields.topicData] = row.topicData
		record[CloudKitOutlineZone.CloudKitRow.Fields.noteData] = row.noteData
		record[CloudKitOutlineZone.CloudKitRow.Fields.isComplete] = row.isComplete ? "1" : "0"
		record[CloudKitOutlineZone.CloudKitRow.Fields.rowOrder] = Array(row.rowOrder)

		addSave(zoneID, record)
	}
	
	private func addSave(zoneID: CKRecordZone.ID, image: Image) -> URL {
		var image = image
		
		image.syncID = UUID().uuidString
		
		let recordID = CKRecord.ID(recordName: image.id.description, zoneID: zoneID)
		let record = CKRecord(recordType: CloudKitOutlineZone.CloudKitImage.recordType, recordID: recordID)
		
		let rowID = EntityID.row(image.id.accountID, image.id.documentUUID, image.id.rowUUID)
		let rowRecordID = CKRecord.ID(recordName: rowID.description, zoneID: zoneID)
		
		record.parent = CKRecord.Reference(recordID: rowRecordID, action: .none)
		record[CloudKitOutlineZone.CloudKitImage.Fields.row] = CKRecord.Reference(recordID: rowRecordID, action: .deleteSelf)
		record[CloudKitOutlineZone.CloudKitImage.Fields.isInNotes] = image.isInNotes
		record[CloudKitOutlineZone.CloudKitImage.Fields.offset] = image.offset
		record[CloudKitOutlineZone.CloudKitImage.Fields.syncID] = image.syncID

		let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent(image.id.imageUUID).appendingPathExtension("png")
		try? image.data.write(to: imageURL)
		record[CloudKitOutlineZone.CloudKitImage.Fields.asset] = CKAsset(fileURL: imageURL)

		addSave(zoneID, record)
		
		return imageURL
	}
	
	private func addSave(_ zoneID: CKRecordZone.ID, _ record: CKRecord) {
		if let (saves, deletes) = modifications[zoneID] {
			var mutableSaves = saves
			mutableSaves.append(record)
			modifications[zoneID] = (mutableSaves, deletes)
		} else {
			var saves = [CKRecord]()
			saves.append(record)
			let deletes = [CKRecord.ID]()
			modifications[zoneID] = (saves, deletes)
		}
	}
	
	private func addDelete(_ request: CloudKitActionRequest) {
		let zoneID = request.zoneID
		let recordID = CKRecord.ID(recordName: request.id.description, zoneID: zoneID)
		addDelete(zoneID, recordID)
	}
	
	private func addDelete(_ zoneID: CKRecordZone.ID, _ recordID: CKRecord.ID) {
		if let (saves, deletes) = modifications[zoneID] {
			var mutableDeletes = deletes
			mutableDeletes.append(recordID)
			modifications[zoneID] = (saves, mutableDeletes)
		} else {
			let saves = [CKRecord]()
			var deletes = [CKRecord.ID]()
			deletes.append(recordID)
			modifications[zoneID] = (saves, deletes)
		}
	}
	
	private func fetchAllChanges(completion: (() -> Void)? = nil) {
		isSyncing = true
		var zoneIDs = Set<CKRecordZone.ID>()
		zoneIDs.insert(defaultZone.zoneID)
		
		let op = CKFetchDatabaseChangesOperation(previousServerChangeToken: sharedDatabaseChangeToken)
		op.qualityOfService = CloudKitOutlineZone.qualityOfService
		
		op.recordZoneWithIDWasDeletedBlock = { zoneID in
			zoneIDs.insert(zoneID)
		}

		op.recordZoneWithIDChangedBlock = { zoneID in
			zoneIDs.insert(zoneID)
		}
		
		op.fetchDatabaseChangesCompletionBlock = { [weak self] token, _, error in
			guard let self = self else {
				completion?()
				return
			}
			
			let group = DispatchGroup()
			
			for zoneID in zoneIDs {
				group.enter()
				self.fetchChanges(zoneID: zoneID) {
					group.leave()
				}
			}
				
			group.notify(queue: DispatchQueue.main) {
				self.sharedDatabaseChangeToken = token
				completion?()
				self.isSyncing = false
			}
		}
		
		container.sharedCloudDatabase.add(op)
	}
	
	private func fetchChanges(zoneID: CKRecordZone.ID, completion: (() -> Void)? = nil) {
		let processInfo = ProcessInfo()
		processInfo.performExpiringActivity(withReason: "Fetching Changes") { expired in
			guard !expired else { return }
			
			var finished = false
			
			let zone = self.findZone(zoneID: zoneID)
			zone.fetchChangesInZone() { [weak self] result in
				if case .failure(let error) = result {
					if let ckError = (error as? CloudKitError)?.error as? CKError, ckError.code == .zoneNotFound {
						AccountManager.shared.cloudKitAccount?.deleteAllDocuments(with: zoneID)
					} else {
						self?.presentError(error)
					}
				}
				completion?()
				finished = true
			}
			
			repeat {
				sleep(1)
			} while(!finished)
		}
		
	}
	
	private func subscribeToSharedDatabaseChanges() {
		let outlineSubscription = sharedDatabaseSubscription(recordType: CloudKitOutlineZone.CloudKitOutline.recordType)
		let rowSubscription = sharedDatabaseSubscription(recordType: CloudKitOutlineZone.CloudKitRow.recordType)

		let op = CKModifySubscriptionsOperation(subscriptionsToSave: [outlineSubscription, rowSubscription], subscriptionIDsToDelete: nil)
		op.qualityOfService = CloudKitOutlineZone.qualityOfService
		
		op.modifySubscriptionsCompletionBlock = { subscriptions, deleted, error in
			if error != nil {
				os_log("Unable to subscribe to shared database.", log: self.log, type: .info)
			}
		}
		
		container.sharedCloudDatabase.add(op)
	}
	
	private func sharedDatabaseSubscription(recordType: String) -> CKDatabaseSubscription {
		let subscription = CKDatabaseSubscription()
		subscription.recordType = recordType

		let notificationInfo = CKSubscription.NotificationInfo()
		notificationInfo.shouldSendContentAvailable = true
		subscription.notificationInfo = notificationInfo
		
		return subscription
	}
	
	var sharedDatabaseChangeTokenKey: String {
		return "cloudkit.server.token.sharedDatabase"
	}

	var sharedDatabaseChangeToken: CKServerChangeToken? {
		get {
			guard let tokenData = UserDefaults.standard.object(forKey: sharedDatabaseChangeTokenKey) as? Data else { return nil }
			return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
		}
		set {
			guard let token = newValue, let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false) else {
				UserDefaults.standard.removeObject(forKey: sharedDatabaseChangeTokenKey)
				return
			}
			UserDefaults.standard.set(data, forKey: sharedDatabaseChangeTokenKey)
		}
	}
	
}

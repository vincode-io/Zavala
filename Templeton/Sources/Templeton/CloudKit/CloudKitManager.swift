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
	static let CloudKitSyncWillBegin = Notification.Name(rawValue: "CloudKitSyncWillBegin")
	static let CloudKitSyncDidComplete = Notification.Name(rawValue: "CloudKitSyncDidComplete")
}

public class CloudKitManager {

	class CombinedRequest {
		var documentRequest: CloudKitActionRequest?
		var rowRequests = [CloudKitActionRequest]()
		var imageRequests = [CloudKitActionRequest]()
	}

	let outlineZone: CloudKitOutlineZone
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

	private var sendChangesBackgroundTaskID = UIBackgroundTaskIdentifier.invalid

	private var coalescingQueue = CoalescingQueue(name: "Send Modifications", interval: 5, maxInterval: 5)
	private var zones = [CKRecordZone.ID: CloudKitOutlineZone]()
	private let queue = MainThreadOperationQueue()

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
		self.outlineZone = CloudKitOutlineZone(container: container)
		outlineZone.delegate = CloudKitOutlineZoneDelegate(account: account, zoneID: self.outlineZone.zoneID)
		self.zones[outlineZone.zoneID] = outlineZone
		self.errorHandler = errorHandler
		migrateSharedDatabaseChangeToken()
		outlineZone.migrateChangeToken()
	}
	
	func firstTimeSetup() {
		outlineZone.fetchZoneRecord {  [weak self] result in
			switch result {
			case .success:
				self?.outlineZone.subscribeToZoneChanges()
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
		let operation = CloudKitQueueRequestsOperation(requests: requests)
		
		operation.completionBlock = { [weak self] op in
			guard let self = self else { return }
			if let error = (op as? BaseMainThreadOperation)?.error {
				self.presentError(error)
			} else {
				self.coalescingQueue.add(self, #selector(self.sendQueuedChanges))
			}
		}
		
		self.queue.add(operation)
	}
	
	func receiveRemoteNotification(userInfo: [AnyHashable : Any], completion: @escaping (() -> Void)) {
		if let zoneNote = CKRecordZoneNotification(fromRemoteNotificationDictionary: userInfo), zoneNote.notificationType == .recordZone {
			guard let zoneId = zoneNote.databaseScope == .private ? outlineZone.zoneID : zoneNote.recordZoneID else {
				completion()
				return
			}
			fetchChanges(userInitiated: false, zoneID: zoneId, completion: completion)
		}
		
		if let dbNote = CKDatabaseNotification(fromRemoteNotificationDictionary: userInfo), dbNote.notificationType == .database {
			fetchAllChanges(userInitiated: false)
		}
	}
	
	func findZone(zoneID: CKRecordZone.ID) -> CloudKitOutlineZone {
		if let zone = zones[zoneID] {
			return zone
		}
		
		let zone = CloudKitOutlineZone(container: container, database: container.sharedCloudDatabase, zoneID: zoneID)
		zone.delegate = CloudKitOutlineZoneDelegate(account: account!, zoneID: zoneID)
		zones[zoneID] = zone
		return zone
	}
	
	func sync(completion: (() -> Void)? = nil) {
		guard isNetworkAvailable else {
			completion?()
			return
		}
		
		cloudKitSyncWillBegin()

		sendChanges(userInitiated: true) { [weak self] in
			self?.fetchAllChanges(userInitiated: true) { [weak self] in
				self?.cloudKitSyncDidComplete()
				completion?()
			}
		}
	}
	
	func userDidAcceptCloudKitShareWith(_ shareMetadata: CKShare.Metadata) {
		let op = CKAcceptSharesOperation(shareMetadatas: [shareMetadata])
		op.qualityOfService = CloudKitOutlineZone.qualityOfService
		
		op.acceptSharesCompletionBlock = { [weak self] error in
			
			guard let self = self else { return }
			
			switch CloudKitResult.refine(error) {
			case .success:
				let zoneID = shareMetadata.share.recordID.zoneID
				self.cloudKitSyncWillBegin()
				self.fetchChanges(userInitiated: true, zoneID: zoneID) { [weak self] in
					self?.cloudKitSyncDidComplete()
				}
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
		zoneIDs.insert(outlineZone.zoneID)
		
		for doc in account.documents ?? [Document]() {
			if let zoneID = doc.zoneID {
				zoneIDs.insert(zoneID)
			}
		}
		
		sharedDatabaseChangeToken = nil
	}
	
}

// MARK: Helpers

private extension CloudKitManager {
	
	func presentError(_ error: Error) {
		errorHandler?.presentError(error, title: "CloudKit Syncing Error")
	}
	
	func cloudKitSyncWillBegin() {
		NotificationCenter.default.post(name: .CloudKitSyncWillBegin, object: self, userInfo: nil)
	}

	func cloudKitSyncDidComplete() {
		NotificationCenter.default.post(name: .CloudKitSyncDidComplete, object: self, userInfo: nil)
	}

	@objc func sendQueuedChanges() {
		guard isNetworkAvailable else {
			return
		}
		sendChanges(userInitiated: false) {
			self.fetchAllChanges(userInitiated: false)
		}
	}

	func sendChanges(userInitiated: Bool, completion: @escaping (() -> Void)) {
		isSyncing = true

		let completeProcessing = { [unowned self] in
			self.isSyncing = false
			
			UIApplication.shared.endBackgroundTask(self.sendChangesBackgroundTaskID)
			self.sendChangesBackgroundTaskID = UIBackgroundTaskIdentifier.invalid
			
			completion()
		}

		self.sendChangesBackgroundTaskID = UIApplication.shared.beginBackgroundTask {
			completeProcessing()
			os_log("CloudKit sync processing terminated for running too long.", log: self.log, type: .info)
		}
		
		let operation = CloudKitModifyOperation()
		
		operation.completionBlock = { [weak self] op in
			if let errors = (op as? CloudKitModifyOperation)?.errors {
				
				for error in errors {
					if case let CloudKitZoneError.unresolvedConflict(ckError) = error {
						#warning("This is the wrong error asshole.")
						self?.presentError(ckError)
					} else {
						if userInitiated {
							self?.presentError(error)
						}
					}
				}
				
			}
			
			completeProcessing()
		}
		
		self.queue.add(operation)
	}
	
	func fetchAllChanges(userInitiated: Bool, completion: (() -> Void)? = nil) {
		isSyncing = true
		var zoneIDs = Set<CKRecordZone.ID>()
		zoneIDs.insert(outlineZone.zoneID)
		
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
				self.fetchChanges(userInitiated: userInitiated, zoneID: zoneID) {
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
	
	func fetchChanges(userInitiated: Bool, zoneID: CKRecordZone.ID, completion: (() -> Void)? = nil) {
		let zone = self.findZone(zoneID: zoneID)
		zone.fetchChangesInZone(incremental: false) { [weak self] result in
			if case .failure(let error) = result {
				if let ckError = error as? CKError, ckError.code == .zoneNotFound {
					AccountManager.shared.cloudKitAccount?.deleteAllDocuments(with: zoneID)
				} else {
					if userInitiated {
						self?.presentError(error)
					}
				}
			}
			completion?()
		}
	}
	
	func subscribeToSharedDatabaseChanges() {
		let outlineSubscription = sharedDatabaseSubscription(recordType: Outline.CloudKitRecord.recordType)
		let rowSubscription = sharedDatabaseSubscription(recordType: Row.CloudKitRecord.recordType)
		let imageSubscription = sharedDatabaseSubscription(recordType: Image.CloudKitRecord.recordType)

		let op = CKModifySubscriptionsOperation(subscriptionsToSave: [outlineSubscription, rowSubscription, imageSubscription], subscriptionIDsToDelete: nil)
		op.qualityOfService = CloudKitOutlineZone.qualityOfService
		
		op.modifySubscriptionsCompletionBlock = { subscriptions, deleted, error in
			if error != nil {
				os_log("Unable to subscribe to shared database.", log: self.log, type: .info)
			}
		}
		
		container.sharedCloudDatabase.add(op)
	}
	
	func sharedDatabaseSubscription(recordType: String) -> CKDatabaseSubscription {
		let subscription = CKDatabaseSubscription()
		subscription.recordType = recordType

		let notificationInfo = CKSubscription.NotificationInfo()
		notificationInfo.shouldSendContentAvailable = true
		subscription.notificationInfo = notificationInfo
		
		return subscription
	}
	
	func migrateSharedDatabaseChangeToken() {
		if let tokenData = UserDefaults.standard.object(forKey: oldSharedDatabaseChangeTokenKey) as? Data {
			account?.sharedDatabaseChangeToken = tokenData
			UserDefaults.standard.removeObject(forKey: oldSharedDatabaseChangeTokenKey)
		}
	}
	
	var oldSharedDatabaseChangeTokenKey: String {
		return "cloudkit.server.token.sharedDatabase"
	}

	var sharedDatabaseChangeToken: CKServerChangeToken? {
		get {
			guard let tokenData = account?.sharedDatabaseChangeToken else { return nil }
			return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
		}
		set {
			guard let token = newValue, let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false) else {
				return
			}
			account?.sharedDatabaseChangeToken = tokenData
		}
	}
	
}

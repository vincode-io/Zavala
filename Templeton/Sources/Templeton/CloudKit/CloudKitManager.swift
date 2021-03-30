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

	let defaultZone: CloudKitOutlineZone
	var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "CloudKit")

	var isSyncAvailable: Bool {
		return !isSyncing && isNetworkAvailable
	}
	
	private let container: CKContainer = {
		let orgID = Bundle.main.object(forInfoDictionaryKey: "OrganizationIdentifier") as! String
		return CKContainer(identifier: "iCloud.\(orgID).Zavala")
	}()

	private weak var account: Account?
	
	private var coalescingQueue = CoalescingQueue(name: "Send Modifications", interval: 5)
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
	
	init(account: Account) {
		self.account = account
		self.defaultZone = CloudKitOutlineZone(container: container)
		defaultZone.delegate = CloudKitAcountZoneDelegate(account: account)
		self.zones[defaultZone.zoneID] = defaultZone
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
		let backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
			guard let self = self else { return }
			os_log("Add requests terminated for running too long.", log: self.log, type: .info)
		}

		let operation = CloudKitQueueRequestsOperation(requests: requests)
		
		operation.completionBlock = { [weak self] op in
			guard let self = self else { return }
			if let error = (op as? BaseMainThreadOperation)?.error {
				self.presentError(error)
			} else {
				self.coalescingQueue.add(self, #selector(self.sendQueuedChanges))
			}
			UIApplication.shared.endBackgroundTask(backgroundTask)
		}
		
		queue.add(operation)
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
		zone.delegate = CloudKitAcountZoneDelegate(account: account!)
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
		if document.isShared {
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
		if let controller = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController {
			if controller.presentedViewController == nil {
				controller.presentError(title: "CloudKit Syncing Error", message: error.localizedDescription)
			}
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
		let backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
			guard let self = self else { return }
			os_log("Send changes terminated for running too long.", log: self.log, type: .info)
		}

		let operation = CloudKitModifyOperation()
		
		operation.completionBlock = { [weak self] op in
			if let error = (op as? BaseMainThreadOperation)?.error {
				self?.presentError(error)
			}
			completion()
			UIApplication.shared.endBackgroundTask(backgroundTask)
			self?.isSyncing = false
		}
		
		queue.add(operation)
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
		let backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
			guard let self = self else { return }
			os_log("Fetch changes terminated for running too long.", log: self.log, type: .info)
		}

		let zone = findZone(zoneID: zoneID)
		zone.fetchChangesInZone() { [weak self] result in
			if case .failure(let error) = result {
				if let ckError = (error as? CloudKitError)?.error as? CKError, ckError.code == .zoneNotFound {
					AccountManager.shared.cloudKitAccount?.deleteAllDocuments(with: zoneID)
				} else {
					self?.presentError(error)
				}
			}
			completion?()
			UIApplication.shared.endBackgroundTask(backgroundTask)
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

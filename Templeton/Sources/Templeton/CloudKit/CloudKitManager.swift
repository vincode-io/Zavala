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
		guard let zoneNote = CKRecordZoneNotification(fromRemoteNotificationDictionary: userInfo) else {
			completion()
			return
		}
		
		guard let zoneId = zoneNote.databaseScope == .private ? defaultZone.zoneID : zoneNote.recordZoneID else {
			completion()
			return
		}
		
		fetchChanges(zoneID: zoneId, completion: completion)
	}
	
	func findZone(zoneID: CKRecordZone.ID) -> CloudKitOutlineZone {
		if let zone = zones[zoneID] {
			return zone
		}
		
		let zone = CloudKitOutlineZone(container: container, database: container.sharedCloudDatabase, zoneID: zoneID)
		zone.delegate = CloudKitAcountZoneDelegate(account: account!)
		zones[zoneID] = zone
		zone.subscribeToZoneChanges()
		return zone
	}
	
	func sync() {
		guard isNetworkAvailable else {
			return
		}
		sendChanges() {
			self.fetchAllChanges() {
				NotificationCenter.default.post(name: .CloudKitSyncDidComplete, object: self, userInfo: nil)
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
	
	func resume() {
		sync()
	}
	
	func suspend() {
		coalescingQueue.performCallsImmediately()
	}
	
	func accountDidDelete() {
		for zone in zones.values {
			zone.resetChangeToken()
		}
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
		sendChanges() {}
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
		
		for doc in account?.documents ?? [Document]() {
			if let zoneID = doc.zoneID {
				zoneIDs.insert(zoneID)
			}
		}
		
		let group = DispatchGroup()
		
		for zoneID in zoneIDs {
			group.enter()
			fetchChanges(zoneID: zoneID) {
				group.leave()
			}
		}
		
		group.notify(queue: DispatchQueue.main) {
			completion?()
			self.isSyncing = false
		}
	}
	
	private func fetchChanges(zoneID: CKRecordZone.ID, completion: (() -> Void)? = nil) {
		let backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
			guard let self = self else { return }
			os_log("Fetch changes terminated for running too long.", log: self.log, type: .info)
		}

		let zone = findZone(zoneID: zoneID)
		zone.fetchChangesInZone() { [weak self] result in
			if case .failure(let error) = result {
				self?.presentError(error)
			}
			completion?()
			UIApplication.shared.endBackgroundTask(backgroundTask)
		}
	}
	
}

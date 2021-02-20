//
//  CloudKitManager.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import UIKit
import os.log
import CloudKit
import RSCore

public class CloudKitManager {

	let defaultZone: CloudKitOutlineZone
	var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "CloudKit")

	private let container: CKContainer = {
		let orgID = Bundle.main.object(forInfoDictionaryKey: "OrganizationIdentifier") as! String
		return CKContainer(identifier: "iCloud.\(orgID).Zavala")
	}()

	private weak var account: Account?
	
	private var coalescingQueue = CoalescingQueue(name: "Send Modifications", interval: 5)
	private var zones = [CKRecordZone.ID: CloudKitOutlineZone]()
	private let queue = MainThreadOperationQueue()

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
		guard let zoneID = CKRecordZoneNotification(fromRemoteNotificationDictionary: userInfo)?.recordZoneID else {
			completion()
			return
		}
		fetchChanges(zoneID: zoneID, completion: completion)
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
	
	func resume() {
		sendChanges() {
			self.fetchAllChanges()
		}
	}
	
	func suspend() {
		coalescingQueue.performCallsImmediately()
	}
	
	func accountWillBeDeleted(_ account: Account) {
		defaultZone.resetChangeToken()
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
		sendChanges() {}
	}

	private func sendChanges(completion: @escaping (() -> Void)) {
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
		}
		
		queue.add(operation)
	}
	
	private func fetchAllChanges(completion: (() -> Void)? = nil) {
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

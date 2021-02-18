//
//  CloudKitManager.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import UIKit
import CloudKit
import RSCore

public class CloudKitManager {

	let defaultZone: CloudKitOutlineZone

	private let container: CKContainer = {
		let orgID = Bundle.main.object(forInfoDictionaryKey: "OrganizationIdentifier") as! String
		return CKContainer(identifier: "iCloud.\(orgID).Zavala")
	}()

	private weak var account: Account?
	
	private var zones = [CKRecordZone.ID: CloudKitOutlineZone]()
	private let queue = MainThreadOperationQueue()

	init(account: Account) {
		self.account = account
		self.defaultZone = CloudKitOutlineZone(container: container)
		defaultZone.delegate = CloudKitAcountZoneDelegate(account: account)
		self.zones[defaultZone.zoneID] = defaultZone
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
			self?.sendModifications()
		}
	}
	
	public func addRequests(_ requests: Set<CloudKitActionRequest>) {
		let operation = CloudKitQueueRequestsOperation(requests: requests)
		operation.completionBlock = { [weak self] op in
			if let error = (op as? BaseMainThreadOperation)?.error {
				self?.presentError(error)
			}
		}
		queue.add(operation)
	}
	
	func findZone(zoneID: CKRecordZone.ID) -> CloudKitOutlineZone? {
		if let zone = zones[zoneID] {
			return zone
		}
		
		guard let account = account else { return nil }
		
		let zone = CloudKitOutlineZone(container: container, database: container.sharedCloudDatabase, zoneID: zoneID)
		zone.delegate = CloudKitAcountZoneDelegate(account: account)
		zones[zoneID] = zone
		return zone
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
	
	private func sendModifications() {
		let operation = CloudKitModifyOperation()
		operation.completionBlock = { [weak self] op in
			if let error = (op as? BaseMainThreadOperation)?.error {
				self?.presentError(error)
			}
		}
		queue.add(operation)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
			self?.sendModifications()
		}
	}
	
}

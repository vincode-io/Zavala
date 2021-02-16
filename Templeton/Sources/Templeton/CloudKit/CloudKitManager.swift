//
//  CloudKitManager.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import Foundation
import CloudKit
import RSCore

public class CloudKitManager {

	static var actionRequestFile: URL {
		return AccountManager.shared.cloudKitAccountFolder.appendingPathComponent("cloudKitRequests.plist")
	}

	private let container: CKContainer = {
		let orgID = Bundle.main.object(forInfoDictionaryKey: "OrganizationIdentifier") as! String
		return CKContainer(identifier: "iCloud.\(orgID).Zavala")
	}()

	private let defaultZone: CloudKitOutlineZone
	private let queue = MainThreadOperationQueue()

	init() {
		defaultZone = CloudKitOutlineZone(container: container)
	}
	
	public func addEntityIDs(_ entityIDs: Set<EntityID>) {
		queue.add(CloudKitQueueEntityIDsOperation(entityIDs: entityIDs))
	}
	
	func accountDidInitialize(_ account: Account) {
		defaultZone.delegate = CloudKitAcountZoneDelegate(account: account)
	}
	
	func accountWillBeDeleted(_ account: Account) {
		defaultZone.resetChangeToken()
	}
	
}

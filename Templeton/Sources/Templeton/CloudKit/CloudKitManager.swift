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

	public static var shared = CloudKitManager()

	static var actionRequestFile: URL {
		return AccountManager.shared.cloudKitAccountFolder.appendingPathComponent("cloudKitRequests.plist")
	}

	private let container: CKContainer = {
		let orgID = Bundle.main.object(forInfoDictionaryKey: "OrganizationIdentifier") as! String
		return CKContainer(identifier: "iCloud.\(orgID).Zavala")
	}()

	private let zones = [CKRecordZone.ID: CloudKitOutlineZone]()
	private let queue = MainThreadOperationQueue()

	init() {
		defaultZone = CloudKitOutlineZone(container: container)
	}
	
	public func addEntityIDs(_ entityIDs: Set<EntityID>) {
		queue.add(CloudKitQueueEntityIDsOperation(entityIDs: entityIDs))
	}
	
	public findZone(zoneName: String, ownerName: String) {
		let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
		if let zone = zones[zoneID] {
			return zone
		}
		
		let zone = CloudKitOutlineZone(container: container, database: container.sharedCloudDatabase, zoneID: zoneID)
		zones[zoneID] = zone
		return zone
	}
	
	func accountDidInitialize(_ account: Account) {
		defaultZone.delegate = CloudKitAcountZoneDelegate(account: account)
	}
	
	func accountWillBeDeleted(_ account: Account) {
		defaultZone.resetChangeToken()
	}
	
}

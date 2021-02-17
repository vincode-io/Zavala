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

	private let container: CKContainer = {
		let orgID = Bundle.main.object(forInfoDictionaryKey: "OrganizationIdentifier") as! String
		return CKContainer(identifier: "iCloud.\(orgID).Zavala")
	}()

	private weak var account: Account?
	
	private let defaultZone: CloudKitOutlineZone
	private var zones = [CKRecordZone.ID: CloudKitOutlineZone]()
	private let queue = MainThreadOperationQueue()

	init(account: Account) {
		self.account = account
		self.defaultZone = CloudKitOutlineZone(container: container)
		defaultZone.delegate = CloudKitAcountZoneDelegate(account: account)
		self.zones[defaultZone.zoneID] = defaultZone
	}
	
	public func addRequests(_ requests: Set<CloudKitActionRequest>) {
		queue.add(CloudKitQueueRequestsOperation(requests: requests))
	}
	
	func findZone(zoneName: String, ownerName: String) -> CloudKitOutlineZone? {
		let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
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

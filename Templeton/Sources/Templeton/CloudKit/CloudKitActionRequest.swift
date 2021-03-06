//
//  CloudKitActionRequest.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation
import CloudKit

public struct CloudKitActionRequest: Codable, Hashable, Equatable {

	static var actionRequestFile: URL {
		return AccountManager.shared.cloudKitAccountFolder.appendingPathComponent("cloudKitRequests.plist")
	}
	
	let zoneName: String
	let zoneOwner: String
	let id: EntityID
	
	var zoneID: CKRecordZone.ID {
		return CKRecordZone.ID(zoneName: zoneName, ownerName: zoneOwner)
	}

	enum CodingKeys: String, CodingKey {
		case zoneName = "zoneName"
		case zoneOwner = "zoneOwner"
		case id = "id"
	}

	public init(zoneName: String, zoneOwner: String, id: EntityID) {
		self.zoneName = zoneName
		self.zoneOwner = zoneOwner
		self.id = id
	}
	
	public init(zoneID: CKRecordZone.ID, id: EntityID) {
		self.zoneName = zoneID.zoneName
		self.zoneOwner = zoneID.ownerName
		self.id = id
	}
	
}

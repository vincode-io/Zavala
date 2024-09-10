//
//  CloudKitActionRequest.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation
import CloudKit

@MainActor
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

	public init(zoneID: CKRecordZone.ID, id: EntityID) {
		self.zoneName = zoneID.zoneName
		self.zoneOwner = zoneID.ownerName
		self.id = id
	}
	
	static func append(requests: Set<CloudKitActionRequest>) {
		guard requests.count != 0 else {
			return
		}

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
		Self.save(requests: mergedRequests)
	}
	
	static func clear() {
		save(requests: Set<CloudKitActionRequest>())
	}
	
	static func load() -> Set<CloudKitActionRequest>? {
		var queuedRequests: Set<CloudKitActionRequest>? = nil
		if let fileData = try? Data(contentsOf: CloudKitActionRequest.actionRequestFile) {
			let decoder = PropertyListDecoder()
			if let decodedRequests = try? decoder.decode(Set<CloudKitActionRequest>.self, from: fileData) {
				queuedRequests = decodedRequests
			}
		}
		return queuedRequests
	}
	
}

// MARK: Helpers

private extension CloudKitActionRequest {
	
	static func save(requests: Set<CloudKitActionRequest>) {
		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		if let encodedIDs = try? encoder.encode(requests) {
			try? encodedIDs.write(to: CloudKitActionRequest.actionRequestFile)
		}
	}
	
}

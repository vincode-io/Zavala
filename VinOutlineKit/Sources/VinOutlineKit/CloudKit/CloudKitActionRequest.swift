//
//  CloudKitActionRequest.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation
import CloudKit
import OrderedCollections

@MainActor
public struct CloudKitActionRequest: Codable, Hashable, Equatable {

	private static var actionRequestFileName = "cloudKitRequests.plist"
	
	let zoneName: String
	let zoneOwner: String
	let id: EntityID
	
	var zoneID: CKRecordZone.ID {
		return CKRecordZone.ID(zoneName: zoneName, ownerName: zoneOwner)
	}
	
	var recordID: CKRecord.ID {
		return CKRecord.ID(recordName: id.description, zoneID: zoneID)
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
	
	static func append(cloudKitAccountFolder: URL, requests: OrderedSet<CloudKitActionRequest>) {
		guard requests.count != 0 else {
			return
		}
		
		let actionRequestFile = cloudKitAccountFolder.appendingPathComponent(Self.actionRequestFileName)

		var queuedRequests: OrderedSet<CloudKitActionRequest>
		
		if let fileData = try? Data(contentsOf: actionRequestFile) {
			let decoder = PropertyListDecoder()
			
			if let decodedRequests = try? decoder.decode(OrderedSet<CloudKitActionRequest>.self, from: fileData) {
				queuedRequests = decodedRequests
			} else if let decodedRequests = try? decoder.decode(Set<CloudKitActionRequest>.self, from: fileData) {
				queuedRequests = OrderedSet(decodedRequests)
			} else {
				queuedRequests = OrderedSet<CloudKitActionRequest>()
			}
		} else {
			queuedRequests = OrderedSet<CloudKitActionRequest>()
		}
		
		queuedRequests.append(contentsOf: requests)
		Self.save(cloudKitAccountFolder: cloudKitAccountFolder, requests: queuedRequests)
	}
	
	static func clear(cloudKitAccountFolder: URL) {
		save(cloudKitAccountFolder: cloudKitAccountFolder, requests: OrderedSet<CloudKitActionRequest>())
	}
	
	static func load(cloudKitAccountFolder: URL) -> OrderedSet<CloudKitActionRequest>? {
		let actionRequestFile = cloudKitAccountFolder.appendingPathComponent(Self.actionRequestFileName)

		var queuedRequests: OrderedSet<CloudKitActionRequest>? = nil
		
		if let fileData = try? Data(contentsOf: actionRequestFile) {
			let decoder = PropertyListDecoder()
			if let decodedRequests = try? decoder.decode(OrderedSet<CloudKitActionRequest>.self, from: fileData) {
				queuedRequests = decodedRequests
			} else if let decodedRequests = try? decoder.decode(Set<CloudKitActionRequest>.self, from: fileData) {
				queuedRequests = OrderedSet(decodedRequests)
			}
		}
		
		return queuedRequests
	}
	
}

// MARK: Helpers

private extension CloudKitActionRequest {
	
	static func save(cloudKitAccountFolder: URL, requests: OrderedSet<CloudKitActionRequest>) {
		let actionRequestFile = cloudKitAccountFolder.appendingPathComponent(Self.actionRequestFileName)

		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		if let encodedIDs = try? encoder.encode(requests) {
			try? encodedIDs.write(to: actionRequestFile)
		}
	}
	
}

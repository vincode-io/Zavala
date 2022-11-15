//
//  CloudKitOutlineZoneDelegate.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import Foundation
import os.log
import RSCore
import CloudKit

class CloudKitOutlineZoneDelegate: CloudKitZoneDelegate {
	
	weak var account: Account?
	var zoneID: CKRecordZone.ID
	
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "CloudKit")
	
	init(account: Account, zoneID: CKRecordZone.ID) {
		self.account = account
		self.zoneID = zoneID
	}
	
	func cloudKitWasChanged(updated: [CKRecord], deleted: [CloudKitRecordKey], completion: @escaping (Result<Void, Error>) -> Void) {
		let pendingIDs = loadPendingIDs()
		var updates = [EntityID: CloudKitOutlineUpdate]()

		func update(for documentID: EntityID, zoneID: CKRecordZone.ID) -> CloudKitOutlineUpdate {
			if let update = updates[documentID] {
				return update
			} else {
				let update = CloudKitOutlineUpdate(documentID: documentID, zoneID: zoneID)
				updates[documentID] = update
				return update
			}
		}

		for deletedRecordKey in deleted {
			guard let entityID = EntityID(description: deletedRecordKey.recordID.recordName), !pendingIDs.contains(entityID) else { continue }
			switch entityID {
			case .document:
				update(for: entityID, zoneID: deletedRecordKey.recordID.zoneID).isDelete = true
			case .row(let accountID, let documentUUID, _):
				let documentID = EntityID.document(accountID, documentUUID)
				update(for: documentID, zoneID: deletedRecordKey.recordID.zoneID).deleteRowRecordIDs.append(entityID)
			case .image(let accountID, let documentUUID, _, _):
				let documentID = EntityID.document(accountID, documentUUID)
				update(for: documentID, zoneID: deletedRecordKey.recordID.zoneID).deleteImageRecordIDs.append(entityID)
			default:
				assertionFailure("Unknown record type: \(deletedRecordKey.recordType)")
			}
		}

		for updatedRecord in updated {
			guard let entityID = EntityID(description: updatedRecord.recordID.recordName), !pendingIDs.contains(entityID) else { continue }
			switch entityID {
			case .document:
				update(for: entityID, zoneID: updatedRecord.recordID.zoneID).saveOutlineRecord = updatedRecord
			case .row(let accountID, let documentUUID, _):
				let documentID = EntityID.document(accountID, documentUUID)
				update(for: documentID, zoneID: updatedRecord.recordID.zoneID).saveRowRecords.append(updatedRecord)
			case .image(let accountID, let documentUUID, _, _):
				let documentID = EntityID.document(accountID, documentUUID)
				update(for: documentID, zoneID: updatedRecord.recordID.zoneID).saveImageRecords.append(updatedRecord)
			default:
				assertionFailure("Unknown record type: \(updatedRecord.recordType)")
			}
		}
		
		for update in updates.values {
			account?.apply(update)
		}
		
		completion(.success(()))
	}

}

// MARK: Helpers

private extension CloudKitOutlineZoneDelegate {
	
	func loadPendingIDs() -> [EntityID] {
		return CloudKitActionRequest.loadRequests()?.filter({ $0.zoneID == zoneID }).map({ $0.id }) ?? [EntityID]()
	}
	
}

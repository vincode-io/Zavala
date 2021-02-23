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

class CloudKitAcountZoneDelegate: CloudKitZoneDelegate {
	
	weak var account: Account?

	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "CloudKit")
	
	init(account: Account) {
		self.account = account
	}
	
	func cloudKitDidModify(changed: [CKRecord], deleted: [CloudKitRecordKey], completion: @escaping (Result<Void, Error>) -> Void) {
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
			guard let entityID = EntityID(description: deletedRecordKey.recordID.recordName) else { continue }
			switch entityID {
			case .document:
				update(for: entityID, zoneID: deletedRecordKey.recordID.zoneID).isDelete = true
			case .row(let accountID, let documentUUID, _):
				let documentID = EntityID.document(accountID, documentUUID)
				update(for: documentID, zoneID: deletedRecordKey.recordID.zoneID).deleteRowRecordIDs.append(entityID)
			default:
				assertionFailure("Unknown record type: \(deletedRecordKey.recordType)")
			}
		}

		for changedRecord in changed {
			guard let entityID = EntityID(description: changedRecord.recordID.recordName) else { continue }
			switch entityID {
			case .document:
				update(for: entityID, zoneID: changedRecord.recordID.zoneID).saveOutlineRecord = changedRecord
			case .row(let accountID, let documentUUID, _):
				let documentID = EntityID.document(accountID, documentUUID)
				update(for: documentID, zoneID: changedRecord.recordID.zoneID).saveRowRecords.append(changedRecord)
			default:
				assertionFailure("Unknown record type: \(changedRecord.recordType)")
			}
		}
		
		for update in updates.values {
			account?.apply(update)
		}
		
		completion(.success(()))
	}

}

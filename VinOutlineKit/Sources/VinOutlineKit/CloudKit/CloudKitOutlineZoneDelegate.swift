//
//  CloudKitOutlineZoneDelegate.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import Foundation
import CloudKit
import VinCloudKit

class CloudKitOutlineZoneDelegate: VCKZoneDelegate {
	
	weak var account: Account?
	var zoneID: CKRecordZone.ID
	
	init(account: Account, zoneID: CKRecordZone.ID) {
		self.account = account
		self.zoneID = zoneID
	}
	
	func store(changeToken: Data?, key: VCKChangeTokenKey) {
		account!.store(changeToken: changeToken, key: key)
	}
	
	func findChangeToken(key: VCKChangeTokenKey) -> Data? {
		return account!.zoneChangeTokens?[key]
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
			case .image(let accountID, let documentUUID, _, _):
				let documentID = EntityID.document(accountID, documentUUID)
				update(for: documentID, zoneID: deletedRecordKey.recordID.zoneID).deleteImageRecordIDs.append(entityID)
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
			case .image(let accountID, let documentUUID, _, _):
				let documentID = EntityID.document(accountID, documentUUID)
				update(for: documentID, zoneID: changedRecord.recordID.zoneID).saveImageRecords.append(changedRecord)
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

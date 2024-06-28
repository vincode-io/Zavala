//
//  CloudKitOutlineZoneDelegate.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import Foundation
import CloudKit
import VinCloudKit

@MainActor
class CloudKitOutlineZoneDelegate: VCKZoneDelegate {
	
	weak var account: Account?
	var zoneID: CKRecordZone.ID
	
	init(account: Account, zoneID: CKRecordZone.ID) {
		self.account = account
		self.zoneID = zoneID
	}
	
	func store(changeToken: Data?, key: VCKChangeTokenKey) async {
		account?.store(changeToken: changeToken, key: key)
	}
	
	func findChangeToken(key: VCKChangeTokenKey) async -> Data? {
		return account?.zoneChangeTokens?[key]
	}
	
	func cloudKitDidModify(changed: [CKRecord], deleted: [CloudKitRecordKey]) async throws {
		var updates = [EntityID: CloudKitOutlineUpdate]()
		var shareUpdates = [(CKRecord.ID, CKShare?)]()

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
			if deletedRecordKey.recordType == CKRecord.SystemType.share {
				shareUpdates.append((deletedRecordKey.recordID, nil))
			} else {
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
		}

		for changedRecord in changed {
			if let shareRecord = changedRecord as? CKShare {
				shareUpdates.append((shareRecord.recordID, shareRecord))
			} else {
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
		}
		
		let updatesToSend = updates
		let shareUpdatesToSend = shareUpdates
		
		for update in updatesToSend.values {
			await account?.apply(update)
		}
		
		// Even though we handle the delete share records here, they don't usually work. That's
		// because the share record id is removed from the outline by the time we get here. No worries.
		// The outline will remove the share record data itself when its recordID gets removed.
		for (shareRecordID, shareRecord) in shareUpdatesToSend {
			if let outline = account?.findDocument(shareRecordID: shareRecordID)?.outline {
				outline.cloudKitShareRecord = shareRecord
			}
		}
	}

}

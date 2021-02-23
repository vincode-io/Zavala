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
	private var updates = [CKRecord.ID: CloudKitOutlineUpdate]()
	
	init(account: Account) {
		self.account = account
	}
	
	func cloudKitDidModify(changed: [CKRecord], deleted: [CloudKitRecordKey], completion: @escaping (Result<Void, Error>) -> Void) {
		for deletedRecordKey in deleted {
			switch deletedRecordKey.recordType {
			case CloudKitOutlineZone.CloudKitOutline.recordType:
				update(for: deletedRecordKey.recordID).isDelete = true
			case CloudKitOutlineZone.CloudKitRow.recordType:
				update(for: deletedRecordKey.recordID).deleteRowRecordIDs.append(deletedRecordKey.recordID)
			default:
				assertionFailure("Unknown record type: \(deletedRecordKey.recordType)")
			}
		}

		for changedRecord in changed {
			switch changedRecord.recordType {
			case CloudKitOutlineZone.CloudKitOutline.recordType:
				update(for: changedRecord.recordID).saveOutlineRecord = changedRecord
			case CloudKitOutlineZone.CloudKitRow.recordType:
				update(for: changedRecord.recordID).saveRowRecords.append(changedRecord)
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

// MARK: Helpers

extension CloudKitAcountZoneDelegate {
	
	private func update(for recordID: CKRecord.ID) -> CloudKitOutlineUpdate {
		if let update = updates[recordID] {
			return update
		} else {
			let update = CloudKitOutlineUpdate(recordID: recordID)
			updates[recordID] = update
			return update
		}
	}
	
}

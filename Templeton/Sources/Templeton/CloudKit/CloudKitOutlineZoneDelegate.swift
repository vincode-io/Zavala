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
	
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "CloudKit")

	weak var account: Account?

	init(account: Account) {
		self.account = account
	}
	
	func cloudKitDidModify(changed: [CKRecord], deleted: [CloudKitRecordKey], completion: @escaping (Result<Void, Error>) -> Void) {
		for deletedRecordKey in deleted {
			switch deletedRecordKey.recordType {
			case CloudKitOutlineZone.CloudKitOutline.recordType:
				account?.deleteDocument(deletedRecordKey.recordID)
			default:
				assertionFailure("Unknown record type: \(deletedRecordKey.recordType)")
			}
		}

		for changedRecord in changed {
			switch changedRecord.recordType {
			case CloudKitOutlineZone.CloudKitOutline.recordType:
				account?.saveOutline(changedRecord)
			default:
				assertionFailure("Unknown record type: \(changedRecord.recordType)")
			}
		}
		
		completion(.success(()))
	}

}

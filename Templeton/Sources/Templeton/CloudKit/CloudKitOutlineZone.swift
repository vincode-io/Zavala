//
//  File.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import Foundation
import os.log
import RSCore
import CloudKit

enum CloudKitOutlineZoneError: LocalizedError {
	case unknown
	var errorDescription: String? {
		return NSLocalizedString("An unexpected CloudKit error occurred.", comment: "An unexpected CloudKit error occurred.")
	}
}

final class CloudKitOutlineZone: CloudKitZone {

	var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "CloudKit")

	var zoneID: CKRecordZone.ID

	weak var container: CKContainer?
	weak var database: CKDatabase?
	var delegate: CloudKitZoneDelegate?
	
	struct CloudKitOutline {
		static let recordType = "Outline"
		struct Fields {
			static let title = "title"
			static let ownerName = "ownerName"
			static let ownerEmail = "ownerEmail"
			static let ownerURL = "ownerURL"
			static let tagNames = "tagNames"
			static let rowOrder = "rowOrder"
		}
	}
	
	struct CloudKitRow {
		static let recordType = "Row"
		struct Fields {
			static let outline = "outline"
			static let subtype = "subtype"
			static let topicData = "topicData"
			static let noteData = "noteData"
			static let isComplete = "isComplete"
			static let rowOrder = "rowOrder"
		}
	}
	
	init(container: CKContainer) {
		self.container = container
		self.database = container.privateCloudDatabase
		self.zoneID = CKRecordZone.ID(zoneName: "Outline", ownerName: CKCurrentUserDefaultName)
	}

	init(container: CKContainer, database: CKDatabase, zoneID: CKRecordZone.ID) {
		self.container = container
		self.database = database
		self.zoneID = zoneID
	}

}

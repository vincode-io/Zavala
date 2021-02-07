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

	static var zoneID: CKRecordZone.ID {
		return CKRecordZone.ID(zoneName: "Outline", ownerName: CKCurrentUserDefaultName)
	}
	
	var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "CloudKit")

	weak var container: CKContainer?
	weak var database: CKDatabase?
	var delegate: CloudKitZoneDelegate?
	
	struct CloudKitTag {
		static let recordType = "Tag"
		struct Fields {
			static let name = "name"
		}
	}
	
	struct CloudKitOutline {
		static let recordType = "Outline"
		struct Fields {
			static let title = "title"
			static let created = "created"
			static let updated = "updated"
			static let ownerName = "ownerName"
			static let ownerEmail = "ownerEmail"
			static let ownerURL = "ownerURL"
			static let tagExternalIDs = "tagExternalIDs"
		}
	}
	
	struct CloudKitRow {
		static let recordType = "Row"
		struct Fields {
			static let topicData = "topicData"
			static let noteData = "noteData"
			static let isComplete = "isComplete"
		}
	}
	
	init(container: CKContainer) {
		self.container = container
		self.database = container.privateCloudDatabase
	}
	
}

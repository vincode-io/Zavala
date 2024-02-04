//
//  File.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import Foundation
import OSLog
import CloudKit
import VinCloudKit

enum CloudKitOutlineZoneError: LocalizedError {
	case unknown
	var errorDescription: String? {
		return NSLocalizedString("An unexpected CloudKit error occurred.", comment: "An unexpected CloudKit error occurred.")
	}
}

final class CloudKitOutlineZone: VCKZone {
	
	var logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinOutlineKit")
	var zoneID: CKRecordZone.ID
	
	weak var container: CKContainer?
	weak var database: CKDatabase?
	var delegate: VCKZoneDelegate?
	
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
	
	func generateCKShare(for document: Document) async throws -> CKShare {
		guard let unsharedRootRecord = try await self.fetch(externalID: document.id.description) else {
			throw CloudKitOutlineZoneError.unknown
		}
		
		let shareID = self.generateRecordID()
		let share = CKShare(rootRecord: unsharedRootRecord, shareID: shareID)
		share[CKShare.SystemFieldKey.title] = (document.title ?? "") as CKRecordValue
		
		let modelsToSave = [CloudKitModelRecordWrapper(share), CloudKitModelRecordWrapper(unsharedRootRecord)]
		let result = try await self.modify(modelsToSave: modelsToSave, recordIDsToDelete: [], strategy: .overWriteServerValue)
		
		return result.0.first! as! CKShare
	}
	
}

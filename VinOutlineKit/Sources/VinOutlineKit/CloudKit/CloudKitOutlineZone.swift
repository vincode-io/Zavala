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
		return NSLocalizedString("label.text.cloudkit-generic-error", comment: "An unexpected CloudKit error occurred.")
	}
}

final class CloudKitOutlineZone: VCKZone {

	static let defaultZoneID = CKRecordZone.ID(zoneName: "Outline", ownerName: CKCurrentUserDefaultName)

	let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinOutlineKit")
	let zoneID: CKRecordZone.ID
	
	let container: CKContainer?
	let database: CKDatabase?
	let delegate: VCKZoneDelegate?
	
	init(container: CKContainer, delegate: VCKZoneDelegate) {
		self.container = container
		self.database = container.privateCloudDatabase
		self.zoneID = CKRecordZone.ID(zoneName: "Outline", ownerName: CKCurrentUserDefaultName)
		self.delegate = delegate
	}
	
	init(container: CKContainer, database: CKDatabase, zoneID: CKRecordZone.ID, delegate: VCKZoneDelegate) {
		self.container = container
		self.database = database
		self.zoneID = zoneID
		self.delegate = delegate
	}
	
	func generateCKShare(for document: Document) async throws -> CKShare {
		guard let unsharedRootRecord = try await self.fetch(externalID: document.id.description) else {
			throw CloudKitOutlineZoneError.unknown
		}
		
		let shareID = self.generateRecordID()
		let share = CKShare(rootRecord: unsharedRootRecord, shareID: shareID)
		share[CKShare.SystemFieldKey.title] = (await document.title ?? "") as CKRecordValue
		
		let modelsToSave = await [CloudKitModelRecordWrapper(share), CloudKitModelRecordWrapper(unsharedRootRecord)]
		let result = try await self.modify(modelsToSave: modelsToSave, recordIDsToDelete: [], strategy: .overWriteServerValue)
		
		return result.0.first! as! CKShare
	}
	
}

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
	case incompatibleVersion
	
	var errorDescription: String? {
		switch self {
		case .unknown:
			return NSLocalizedString("label.text.cloudkit-generic-error", bundle: .module, comment: "An unexpected CloudKit error occurred.")
		case .incompatibleVersion:
			return NSLocalizedString("label.text.cloudkit-zone-version-mismatch", bundle: .module, comment: "The version of the Outline zone in your iCloud account is incompatible with this app.")
		}
	}
}

final class CloudKitOutlineZone: VCKZone {

	static let defaultZoneID = CKRecordZone.ID(zoneName: "Outline", ownerName: CKCurrentUserDefaultName)

	let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinOutlineKit")
	let zoneID: CKRecordZone.ID
	
	let container: CKContainer?
	let database: CKDatabase?
	let delegate: VCKZoneDelegate?

	private let currentZoneVersionNumber = 2
	private let zoneVersionRecordName = "io.vincode.Zavala.zoneVersion"

	private struct VersionRecord {
		static let recordType = "ZoneVersion"
		struct Fields {
			static let versionNumber = "versionNumber"
		}
	}
	
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
	
	func validateZoneVersion() async throws {
		guard zoneID == Self.defaultZoneID else {
			return
		}

		do {
			let versionRecord = try await fetch(externalID: zoneVersionRecordName)
			guard let versionNumber = versionRecord?[VersionRecord.Fields.versionNumber] as? Int else {
				return
			}
			
			if versionNumber != currentZoneVersionNumber {
				throw CloudKitOutlineZoneError.incompatibleVersion
			}
		} catch {
			if let ckError = error as? CKError, ckError.code == .unknownItem {
				try await saveZoneVersionRecord()
			} else {
				throw error
			}
		}
	}
	
}

// MARK: Helpers

private extension CloudKitOutlineZone {

	func saveZoneVersionRecord() async throws {
		let recordID = CKRecord.ID(recordName: zoneVersionRecordName, zoneID: zoneID)
		let newVersionRecord = CKRecord(recordType: VersionRecord.recordType, recordID: recordID)
		newVersionRecord[VersionRecord.Fields.versionNumber] = currentZoneVersionNumber

		try await save(newVersionRecord)
	}

}

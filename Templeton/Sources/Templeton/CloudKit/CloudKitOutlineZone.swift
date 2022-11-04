//
//  File.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import UIKit
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
			static let syncID = "syncID"
			static let title = "title"
			static let ownerName = "ownerName"
			static let ownerEmail = "ownerEmail"
			static let ownerURL = "ownerURL"
			static let created = "created"
			static let updated = "updated"
			static let tagNames = "tagNames"
			static let rowOrder = "rowOrder"
			static let documentLinks = "documentLinks"
			static let documentBacklinks = "documentBacklinks"
			static let hasAltLinks = "hasAltLinks"
			static let disambiguator = "disambiguator"
		}
	}
	
	struct CloudKitRow {
		static let recordType = "Row"
		struct Fields {
			static let syncID = "syncID"
			static let outline = "outline"
			static let subtype = "subtype"
			static let topicData = "topicData"
			static let noteData = "noteData"
			static let isComplete = "isComplete"
			static let rowOrder = "rowOrder"
		}
	}
	
	struct CloudKitImage {
		static let recordType = "Image"
		struct Fields {
			static let syncID = "syncID"
			static let row = "row"
			static let isInNotes = "isInNotes"
			static let offset = "offset"
			static let asset = "asset"
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
	
	func prepareSharedCloudSharingController(document: Document, completion: @escaping (Result<UICloudSharingController, Error>) -> Void) {
		guard let shareRecordID = document.shareRecordID else {
			fatalError()
		}
		
		fetch(externalID: shareRecordID.recordName) { [weak self] result in
			switch result {
			case .success(let record):
				guard let shareRecord = record as? CKShare, let container = self?.container else {
					completion(.failure(CloudKitOutlineZoneError.unknown))
					return
				}
				completion(.success(UICloudSharingController(share: shareRecord, container: container)))
			case .failure:
				self?.prepareNewCloudSharingController(document: document, completion: completion)
			}
		}
	}

	func prepareNewCloudSharingController(document: Document, completion: @escaping (Result<UICloudSharingController, Error>) -> Void) {
		let sharingController = UICloudSharingController { [weak self] (_, prepareCompletionHandler) in

			self?.fetch(externalID: document.id.description) { [weak self] result in
				guard let self = self else {
					completion(.failure(CloudKitOutlineZoneError.unknown))
					return
				}

				switch result {
				case .success(let unsharedRootRecord):
					let shareID = self.generateRecordID()
					let share = CKShare(rootRecord: unsharedRootRecord, shareID: shareID)
					share[CKShare.SystemFieldKey.title] = (document.title ?? "") as CKRecordValue

					self.modify(recordsToSave: [share, unsharedRootRecord], recordIDsToDelete: [], strategy: .overWriteServerValue) { [weak self] result in
						guard let self = self else {
							completion(.failure(CloudKitOutlineZoneError.unknown))
							return
						}
						
						switch result {
						case .success:
							prepareCompletionHandler(share, self.container, nil)
						case .failure(let error):
							prepareCompletionHandler(nil, self.container, error)
						}
					}
				case .failure(let error):
					prepareCompletionHandler(nil, self.container, error)
				}
			}
		}

		completion(.success(sharingController))
	}
	
}

//
//  File.swift
//  
//
//  Created by Maurice Parker on 2/6/21.
//

import UIKit
import os.log
import CloudKit
import VinCloudKit

enum CloudKitOutlineZoneError: LocalizedError {
	case unknown
	var errorDescription: String? {
		return NSLocalizedString("An unexpected CloudKit error occurred.", comment: "An unexpected CloudKit error occurred.")
	}
}

final class CloudKitOutlineZone: CloudKitZone {
	
	var logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Templeton")
	var zoneID: CKRecordZone.ID

	weak var container: CKContainer?
	weak var database: CKDatabase?
	var delegate: CloudKitZoneDelegate?
		
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
				guard let self else {
					completion(.failure(CloudKitOutlineZoneError.unknown))
					return
				}

				switch result {
				case .success(let unsharedRootRecord):
					let shareID = self.generateRecordID()
					let share = CKShare(rootRecord: unsharedRootRecord, shareID: shareID)
					share[CKShare.SystemFieldKey.title] = (document.title ?? "") as CKRecordValue

					self.modify(recordsToSave: [share, unsharedRootRecord], recordIDsToDelete: [], strategy: .overWriteServerValue) { [weak self] result in
						guard let self else {
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

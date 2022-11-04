//
//  CloudKitModifyOperation.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation
import CloudKit
import RSCore

class CloudKitModifyOperation: BaseMainThreadOperation {

	var modifications = [CKRecordZone.ID: ([CKRecord], [CKRecord.ID])]()

	class CombinedRequest {
		var documentRequest: CloudKitActionRequest?
		var rowRequests = [CloudKitActionRequest]()
		var imageRequests = [CloudKitActionRequest]()
	}
	
	override func run() {
		DispatchQueue.global().async {
			let combinedRequests = self.loadRequests()
			DispatchQueue.main.async {
				self.send(combinedRequests: combinedRequests) {
					self.operationDelegate?.operationDidComplete(self)
				}
			}
		}
	}
	
}

// MARK: Helpers

private extension CloudKitModifyOperation {
	
	func send(combinedRequests: [String : CombinedRequest], completion: @escaping (() -> Void)) {
		guard !combinedRequests.isEmpty,
			  let account = AccountManager.shared.cloudKitAccount,
			  let cloudKitManager = account.cloudKitManager else {
			completion()
			return
		}
		
		var loadedDocuments = [Document]()
		var tempFileURLs = [URL]()

		for documentUUID in combinedRequests.keys {
			guard let combinedRequest = combinedRequests[documentUUID] else { continue }
			
			// If we don't have a document, we probably have a delete request to send.
			// We don't have to continue processing since we cascade delete our rows.
			guard let document = account.findDocument(documentUUID: documentUUID) else {
				if let docRequest = combinedRequest.documentRequest {
					addDelete(docRequest)
				}
				continue
			}
			
			document.load()
			loadedDocuments.append(document)
			
			// This has to be a save for the document
			if combinedRequest.documentRequest != nil {
				addSave(document)
			}

			guard let outline = document.outline, let zoneID = outline.zoneID else { continue }
			let outlineRecordID = CKRecord.ID(recordName: outline.id.description, zoneID: zoneID)
			
			// Now process all the rows
			for imageRequest in combinedRequest.rowRequests {
				if let row = outline.findRow(id: imageRequest.id.rowUUID) {
					outline.updateRowSyncID(row)
					addSave(zoneID: zoneID, outlineRecordID: outlineRecordID, row: row)
				} else {
					addDelete(imageRequest)
				}
			}
			
			// Now process all the images
			for imageRequest in combinedRequest.imageRequests {
				// if the row is gone, we don't need to process the images because we cascade our deletes
				if let row = outline.findRow(id: imageRequest.id.rowUUID) {
					if let image = row.findImage(id: imageRequest.id) {
						outline.updateImageSyncID(image)
						let tempFileURL = addSave(zoneID: zoneID, image: image)
						tempFileURLs.append(tempFileURL)
					} else {
						addDelete(imageRequest)
					}
				}
			}
		}
		
		// Send the grouped changes

		func updateSyncMetaData(savedRecords: [CKRecord]) {
			for savedRecord in savedRecords {
				guard let entityID = EntityID(description: savedRecord.recordID.recordName),
						let outline = account.findDocument(entityID)?.outline else { continue }
				
				switch savedRecord.recordType {
				case "Outline":
					outline.syncMetaData = savedRecord.metadata
				case "Row":
					(outline.findRowContainer(entityID: entityID) as? Row)?.syncMetaData = savedRecord.metadata
				case "Image":
					(outline.findRowContainer(entityID: entityID) as? Row)?.findImage(id: entityID)?.syncMetaData = savedRecord.metadata
				default:
					break
				}
			}
		}
		
		var savedRecords = [CKRecord]()
		var deletedRecordIDs = [CKRecord.ID]()
		
		let group = DispatchGroup()
		for zoneID in modifications.keys {
			group.enter()

			let cloudKitZone = cloudKitManager.findZone(zoneID: zoneID)
			let (saves, deletes) = modifications[zoneID]!

			let strategy = CloudKitModifyStrategy.onlyIfServerUnchanged(CloudKitMergeResolver())
			cloudKitZone.modify(recordsToSave: saves, recordIDsToDelete: deletes, strategy: strategy) { [weak self] result in
				guard let self else { return }
				
				switch result {
				case .success(let (completedSaves, completedDeletes)):
					savedRecords.append(contentsOf: completedSaves)
					deletedRecordIDs.append(contentsOf: completedDeletes)
				case .failure(let error):
					if case let CloudKitZoneError.unresolvedConflict(ckError) = error {
						
					}
					self.error = error
				}
				
				group.leave()
			}
		}
		
		group.notify(queue: DispatchQueue.main) {
			updateSyncMetaData(savedRecords: savedRecords)
			
			loadedDocuments.forEach { $0.unload() }
			
			if self.error == nil {
				self.deleteRequests()
			}
			
			self.deleteTempFiles(tempFileURLs)
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
	func loadRequests() -> [String: CombinedRequest] {
		var combinedRequests = [String: CombinedRequest]()

		guard let queuedRequests = CloudKitActionRequest.loadRequests(), !queuedRequests.isEmpty else { return combinedRequests }
		
		for queuedRequest in queuedRequests {
			switch queuedRequest.id {
			case .document(_, let documentUUID):
				if let combinedRequest = combinedRequests[documentUUID] {
					combinedRequest.documentRequest = queuedRequest
					combinedRequests[documentUUID] = combinedRequest
				} else {
					let combinedRequest = CombinedRequest()
					combinedRequest.documentRequest = queuedRequest
					combinedRequests[documentUUID] = combinedRequest
				}
			case .row(_, let documentUUID, _):
				if let combinedRequest = combinedRequests[documentUUID] {
					combinedRequest.rowRequests.append(queuedRequest)
					combinedRequests[documentUUID] = combinedRequest
				} else {
					let combinedRequest = CombinedRequest()
					combinedRequest.rowRequests.append(queuedRequest)
					combinedRequests[documentUUID] = combinedRequest
				}
			case .image(_, let documentUUID, _, _):
				if let combinedRequest = combinedRequests[documentUUID] {
					combinedRequest.imageRequests.append(queuedRequest)
					combinedRequests[documentUUID] = combinedRequest
				} else {
					let combinedRequest = CombinedRequest()
					combinedRequest.imageRequests.append(queuedRequest)
					combinedRequests[documentUUID] = combinedRequest
				}
			default:
				fatalError()
			}
		}
		
		return combinedRequests
	}
	
	func deleteRequests() {
		try? FileManager.default.removeItem(at: CloudKitActionRequest.actionRequestFile)
	}
	
	func deleteTempFiles(_ urls: [URL]) {
		for url in urls {
			try? FileManager.default.removeItem(at: url)
		}
	}
	
	func addSave(_ document: Document) {
		guard let outline = document.outline, let zoneID = outline.zoneID else { return }
		
		outline.syncID = UUID().uuidString
		
		let record: CKRecord = {
			if let syncMetaData = outline.syncMetaData, let record = CKRecord(syncMetaData) {
				return record
			} else {
				let recordID = CKRecord.ID(recordName: outline.id.description, zoneID: zoneID)
				return CKRecord(recordType: CloudKitOutlineZone.CloudKitOutline.recordType, recordID: recordID)
			}
		}()
		
		record[CloudKitOutlineZone.CloudKitOutline.Fields.syncID] = outline.syncID
		record[CloudKitOutlineZone.CloudKitOutline.Fields.title] = outline.title
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerName] = outline.ownerName
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerEmail] = outline.ownerEmail
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerURL] = outline.ownerURL
		record[CloudKitOutlineZone.CloudKitOutline.Fields.created] = outline.created
		record[CloudKitOutlineZone.CloudKitOutline.Fields.updated] = outline.updated
		record[CloudKitOutlineZone.CloudKitOutline.Fields.tagNames] = outline.tags.map { $0.name }
		if let rowOrder = outline.rowOrder {
			record[CloudKitOutlineZone.CloudKitOutline.Fields.rowOrder] = Array(rowOrder)
		}
		record[CloudKitOutlineZone.CloudKitOutline.Fields.documentLinks] = outline.documentLinks?.map { $0.description }
		record[CloudKitOutlineZone.CloudKitOutline.Fields.documentBacklinks] = outline.documentBacklinks?.map { $0.description }
		record[CloudKitOutlineZone.CloudKitOutline.Fields.hasAltLinks] = outline.hasAltLinks
		record[CloudKitOutlineZone.CloudKitOutline.Fields.disambiguator] = outline.disambiguator

		addSave(zoneID, record)
	}
	
	func addSave(zoneID: CKRecordZone.ID, outlineRecordID: CKRecord.ID, row: Row) {
		let record: CKRecord = {
			if let syncMetaData = row.syncMetaData, let record = CKRecord(syncMetaData) {
				return record
			} else {
				let recordID = CKRecord.ID(recordName: row.entityID.description, zoneID: zoneID)
				return CKRecord(recordType: CloudKitOutlineZone.CloudKitRow.recordType, recordID: recordID)
			}
		}()

		record.parent = CKRecord.Reference(recordID: outlineRecordID, action: .none)
		record[CloudKitOutlineZone.CloudKitRow.Fields.outline] = CKRecord.Reference(recordID: outlineRecordID, action: .deleteSelf)
		record[CloudKitOutlineZone.CloudKitRow.Fields.syncID] = row.syncID
		record[CloudKitOutlineZone.CloudKitRow.Fields.subtype] = "text"
		record[CloudKitOutlineZone.CloudKitRow.Fields.topicData] = row.topicData
		record[CloudKitOutlineZone.CloudKitRow.Fields.noteData] = row.noteData
		record[CloudKitOutlineZone.CloudKitRow.Fields.isComplete] = row.isComplete ? "1" : "0"
		record[CloudKitOutlineZone.CloudKitRow.Fields.rowOrder] = Array(row.rowOrder)

		addSave(zoneID, record)
	}
	
	func addSave(zoneID: CKRecordZone.ID, image: Image) -> URL {
		let record: CKRecord = {
			if let syncMetaData = image.syncMetaData, let record = CKRecord(syncMetaData) {
				return record
			} else {
				let recordID = CKRecord.ID(recordName: image.id.description, zoneID: zoneID)
				return CKRecord(recordType: CloudKitOutlineZone.CloudKitImage.recordType, recordID: recordID)
			}
		}()
		
		let rowID = EntityID.row(image.id.accountID, image.id.documentUUID, image.id.rowUUID)
		let rowRecordID = CKRecord.ID(recordName: rowID.description, zoneID: zoneID)
		
		record.parent = CKRecord.Reference(recordID: rowRecordID, action: .none)
		record[CloudKitOutlineZone.CloudKitImage.Fields.row] = CKRecord.Reference(recordID: rowRecordID, action: .deleteSelf)
		record[CloudKitOutlineZone.CloudKitImage.Fields.isInNotes] = image.isInNotes
		record[CloudKitOutlineZone.CloudKitImage.Fields.offset] = image.offset
		record[CloudKitOutlineZone.CloudKitImage.Fields.syncID] = image.syncID

		let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent(image.id.imageUUID).appendingPathExtension("png")
		try? image.data.write(to: imageURL)
		record[CloudKitOutlineZone.CloudKitImage.Fields.asset] = CKAsset(fileURL: imageURL)

		addSave(zoneID, record)
		
		return imageURL
	}
	
	func addSave(_ zoneID: CKRecordZone.ID, _ record: CKRecord) {
		if let (saves, deletes) = modifications[zoneID] {
			var mutableSaves = saves
			mutableSaves.append(record)
			modifications[zoneID] = (mutableSaves, deletes)
		} else {
			var saves = [CKRecord]()
			saves.append(record)
			let deletes = [CKRecord.ID]()
			modifications[zoneID] = (saves, deletes)
		}
	}
	
	func addDelete(_ request: CloudKitActionRequest) {
		let zoneID = request.zoneID
		let recordID = CKRecord.ID(recordName: request.id.description, zoneID: zoneID)
		addDelete(zoneID, recordID)
	}
	
	func addDelete(_ zoneID: CKRecordZone.ID, _ recordID: CKRecord.ID) {
		if let (saves, deletes) = modifications[zoneID] {
			var mutableDeletes = deletes
			mutableDeletes.append(recordID)
			modifications[zoneID] = (saves, mutableDeletes)
		} else {
			let saves = [CKRecord]()
			var deletes = [CKRecord.ID]()
			deletes.append(recordID)
			modifications[zoneID] = (saves, deletes)
		}
	}
	
}

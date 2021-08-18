//
//  CloudKitModifyOperation.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation
import CloudKit

class CloudKitModifyOperation: BaseMainThreadOperation {

	var modifications = [CKRecordZone.ID: ([CKRecord], [CKRecord.ID])]()

	class CombinedRequest {
		var documentRequest: CloudKitActionRequest?
		var rowRequests = [CloudKitActionRequest]()
	}
	
	override func run() {
		guard let account = AccountManager.shared.cloudKitAccount,
			  let cloudKitManager = account.cloudKitManager else {
			operationDelegate?.operationDidComplete(self)
			return
		}
		
		let combinedRequests = loadRequests()
		
		guard !combinedRequests.isEmpty else {
			operationDelegate?.operationDidComplete(self)
			return
		}
		
		var loadedDocuments = [Document]()
		
		for documentUUID in combinedRequests.keys {
			guard let combinedRequest = combinedRequests[documentUUID] else { continue }
			
			// If we don't have a document, we probably have a delete request to send.
			// We don't have to continue processing since we cascade delete our rows.
			guard let document = account.findDocument(documentUUID: documentUUID) else {
				if let docRequest = combinedRequest.documentRequest {
					addDeleteDocument(docRequest)
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
			for rowRequest in combinedRequest.rowRequests {
				if let row = outline.findRow(id: rowRequest.id.rowUUID) {
					addSave(zoneID: zoneID, outlineRecordID: outlineRecordID, row: row)
				} else {
					addDeleteRow(rowRequest)
				}
			}
			
		}
		
		// Send the grouped changes
		
		var tempFileURLs = [URL]()
		let group = DispatchGroup()
		
		for zoneID in modifications.keys {
			group.enter()

			let cloudKitZone = cloudKitManager.findZone(zoneID: zoneID)
			let (saves, deletes) = modifications[zoneID]!

			if let imageQuery = buildImageQuery(saves: saves) {
				cloudKitZone.query(imageQuery, desiredKeys: []) { result in
					switch result {
					case .success(let imageRecords):
						var (moreSaves, moreDeletes, imageURLs) = self.trueUpImageRecordIDs(zoneID: zoneID, saves: saves, imageRecords: imageRecords)
						moreSaves.append(contentsOf: saves)
						moreDeletes.append(contentsOf: deletes)
						tempFileURLs.append(contentsOf: imageURLs)
						
						cloudKitZone.modify(recordsToSave: moreSaves, recordIDsToDelete: moreDeletes) { result in
							if case .failure(let error) = result {
								self.error = error
							}
							group.leave()
						}
					case .failure(let error):
						self.error = error
						group.leave()
					}
				}
			} else {
				cloudKitZone.modify(recordsToSave: saves, recordIDsToDelete: deletes) { result in
					if case .failure(let error) = result {
						self.error = error
					}
					group.leave()
				}
			}
		}
		
		group.notify(queue: DispatchQueue.main) {
			loadedDocuments.forEach { $0.unload() }
			if self.error == nil {
				self.deleteRequests()
				self.deleteTempFiles(tempFileURLs)
			}
			self.operationDelegate?.operationDidComplete(self)
		}
	}
	
}

extension CloudKitModifyOperation {
	
	private func loadRequests() -> [String: CombinedRequest] {
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
			default:
				fatalError()
			}
		}
		
		return combinedRequests
	}
	
	private func deleteRequests() {
		try? FileManager.default.removeItem(at: CloudKitActionRequest.actionRequestFile)
	}
	
	private func deleteTempFiles(_ urls: [URL]) {
		for url in urls {
			try? FileManager.default.removeItem(at: url)
		}
	}
	
	private func addSave(_ document: Document) {
		guard let outline = document.outline, let zoneID = outline.zoneID else { return }
		
		outline.syncID = UUID().uuidString
		
		let recordID = CKRecord.ID(recordName: outline.id.description, zoneID: zoneID)
		let record = CKRecord(recordType: CloudKitOutlineZone.CloudKitOutline.recordType, recordID: recordID)
		
		record[CloudKitOutlineZone.CloudKitOutline.Fields.syncID] = outline.syncID
		record[CloudKitOutlineZone.CloudKitOutline.Fields.title] = outline.title
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerName] = outline.ownerName
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerEmail] = outline.ownerEmail
		record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerURL] = outline.ownerURL
		record[CloudKitOutlineZone.CloudKitOutline.Fields.created] = outline.created
		record[CloudKitOutlineZone.CloudKitOutline.Fields.updated] = outline.updated
		record[CloudKitOutlineZone.CloudKitOutline.Fields.tagNames] = outline.tags.map { $0.name }
		record[CloudKitOutlineZone.CloudKitOutline.Fields.rowOrder] = outline.rowOrder
		record[CloudKitOutlineZone.CloudKitOutline.Fields.documentLinks] = outline.documentLinks?.map { $0.description }
		record[CloudKitOutlineZone.CloudKitOutline.Fields.documentBacklinks] = outline.documentBacklinks?.map { $0.description }

		addSave(zoneID, record)
	}
	
	private func addSave(zoneID: CKRecordZone.ID, outlineRecordID: CKRecord.ID, row: Row) {
		guard let textRow = row.textRow else { return }
		
		textRow.syncID = UUID().uuidString
		
		let recordID = CKRecord.ID(recordName: textRow.entityID.description, zoneID: zoneID)
		let record = CKRecord(recordType: CloudKitOutlineZone.CloudKitRow.recordType, recordID: recordID)
		
		record.parent = CKRecord.Reference(recordID: outlineRecordID, action: .none)
		record[CloudKitOutlineZone.CloudKitRow.Fields.outline] = CKRecord.Reference(recordID: outlineRecordID, action: .deleteSelf)
		record[CloudKitOutlineZone.CloudKitRow.Fields.syncID] = textRow.syncID
		record[CloudKitOutlineZone.CloudKitRow.Fields.subtype] = "text"
		record[CloudKitOutlineZone.CloudKitRow.Fields.topicData] = textRow.topicData
		record[CloudKitOutlineZone.CloudKitRow.Fields.noteData] = textRow.noteData
		record[CloudKitOutlineZone.CloudKitRow.Fields.isComplete] = textRow.isComplete ? "1" : "0"
		record[CloudKitOutlineZone.CloudKitRow.Fields.rowOrder] = textRow.rowOrder

		addSave(zoneID, record)
	}
	
	private func addSave(_ zoneID: CKRecordZone.ID, _ record: CKRecord) {
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
	
	private func addDeleteDocument(_ request: CloudKitActionRequest) {
		let zoneID = request.zoneID
		let recordID = CKRecord.ID(recordName: request.id.description, zoneID: zoneID)
		addDelete(zoneID, recordID)
	}
	
	private func addDeleteRow(_ request: CloudKitActionRequest) {
		let zoneID = request.zoneID
		let recordID = CKRecord.ID(recordName: request.id.description, zoneID: zoneID)
		addDelete(zoneID, recordID)
	}
	
	private func addDelete(_ zoneID: CKRecordZone.ID, _ recordID: CKRecord.ID) {
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
	
	private func buildImageQuery(saves: [CKRecord]) -> CKQuery? {
		let rowReferences = saves
			.filter { $0.recordType == CloudKitOutlineZone.CloudKitRow.recordType }
			.map { CKRecord.Reference(recordID: $0.recordID, action: .deleteSelf) }
		
		guard !rowReferences.isEmpty else { return nil }
		
		let predicate = NSPredicate(format: "row IN %@", rowReferences)
		let ckQuery = CKQuery(recordType: CloudKitOutlineZone.CloudKitImage.recordType, predicate: predicate)
		
		return ckQuery
	}
	
	private func trueUpImageRecordIDs(zoneID: CKRecordZone.ID, saves: [CKRecord], imageRecords: [CKRecord]) -> ([CKRecord], [CKRecord.ID], [URL]) {
		let imageRecordIDs = imageRecords.compactMap { EntityID(description: $0.recordID.recordName) }
		
		var imageSaves = [CKRecord]()
		var imageDeletes = [CKRecord.ID]()
		var imageURLs = [URL]()
		
		let saveRecords = saves.filter { $0.recordType == CloudKitOutlineZone.CloudKitRow.recordType }
		let saveEntityIDs = saveRecords.compactMap { EntityID(description: $0.recordID.recordName) }
		let saveRows = saveEntityIDs.compactMap { AccountManager.shared.findRow($0) }
		let saveImages = saveRows.flatMap { $0.images }
		
		for image in saveImages {
			if !imageRecordIDs.contains(image.id) {
				let recordID = CKRecord.ID(recordName: image.id.description, zoneID: zoneID)
				let record = CKRecord(recordType: CloudKitOutlineZone.CloudKitImage.recordType, recordID: recordID)
				
				let rowID = EntityID.row(image.id.accountID, image.id.documentUUID, image.id.rowUUID)
				let rowRecordID = CKRecord.ID(recordName: rowID.description, zoneID: zoneID)
				
				record.parent = CKRecord.Reference(recordID: rowRecordID, action: .none)
				record[CloudKitOutlineZone.CloudKitImage.Fields.row] = CKRecord.Reference(recordID: rowRecordID, action: .deleteSelf)
				record[CloudKitOutlineZone.CloudKitImage.Fields.isInNotes] = image.isInNotes
				record[CloudKitOutlineZone.CloudKitImage.Fields.offset] = image.offset
				
				let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent(image.id.imageUUID).appendingPathExtension("png")
				imageURLs.append(imageURL)
				try? image.data.write(to: imageURL)
				record[CloudKitOutlineZone.CloudKitImage.Fields.asset] = CKAsset(fileURL: imageURL)

				imageSaves.append(record)
			}
		}
		
		for imageRecordID in imageRecordIDs {
			let rowID = EntityID.row(imageRecordID.accountID, imageRecordID.documentUUID, imageRecordID.rowUUID)
			guard let row = AccountManager.shared.findRow(rowID) else { continue }

			if !row.images.contains(where: { $0.id == imageRecordID }) {
				imageDeletes.append(CKRecord.ID(recordName: imageRecordID.description, zoneID: zoneID))
			}
		}
		
		return (imageSaves, imageDeletes, imageURLs)
	}
	
}

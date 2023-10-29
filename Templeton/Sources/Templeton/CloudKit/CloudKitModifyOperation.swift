//
//  CloudKitModifyOperation.swift
//  
//
//  Created by Maurice Parker on 2/15/21.
//

import Foundation
import CloudKit
import os.log
import VinCloudKit

class CloudKitModifyOperation: BaseMainThreadOperation {
	
	var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Templeton")

	var errors = [Error]()
	var modifications = [CKRecordZone.ID: ([CKRecord], [CKRecord.ID])]()

	var account: Account {
		return AccountManager.shared.cloudKitAccount!
	}
	
	var cloudKitManager: CloudKitManager {
		account.cloudKitManager!
	}
	
	class CombinedRequest {
		var documentRequest: CloudKitActionRequest?
		var rowRequests = [CloudKitActionRequest]()
		var imageRequests = [CloudKitActionRequest]()
	}
	
	override func run() {
		DispatchQueue.global().async {
			guard let requests = CloudKitActionRequest.loadRequests(), !requests.isEmpty else {
				DispatchQueue.main.async {
					self.operationDelegate?.operationDidComplete(self)
				}
				return
			}
			DispatchQueue.main.async {
				self.send(requests: requests)
			}
		}
	}
	
}

// MARK: Helpers

private extension CloudKitModifyOperation {
	
	func send(requests: Set<CloudKitActionRequest>) {
		logger.info("Sending \(requests.count) requests.")
		
		let (loadedDocuments, tempFileURLs) = loadAndStageEntities(requests: requests)

		// Send the grouped changes
		
		var leftOverRequests = requests
		
		let group = DispatchGroup()
		for zoneID in modifications.keys {
			group.enter()

			let cloudKitZone = cloudKitManager.findZone(zoneID: zoneID)
			let (recordsToSave, recordIDsToDelete) = modifications[zoneID]!

			let strategy = CloudKitModifyStrategy.onlyIfServerUnchanged(CloudKitMergeResolver())
			cloudKitZone.modify(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete, strategy: strategy) { [weak self] result in
				guard let self else { return }
				
				switch result {
				case .success(let (completedSaves, completedDeletes)):
					self.updateSyncMetaData(savedRecords: completedSaves)
					
					let savedEntityIDs = completedSaves.compactMap { EntityID(description: $0.recordID.recordName) }
					leftOverRequests.subtract(savedEntityIDs.map { CloudKitActionRequest(zoneID: zoneID, id: $0) })
					
					let deletedEntityIDs = completedDeletes.compactMap { EntityID(description: $0.recordName) }
					leftOverRequests.subtract(deletedEntityIDs.map { CloudKitActionRequest(zoneID: zoneID, id: $0) })
				case .failure(let error):
					self.errors.append(error)
				}
				
				group.leave()
			}
		}
		
		group.notify(queue: DispatchQueue.main) {
			loadedDocuments.forEach { $0.unload() }
			
			DispatchQueue.global().async {
				self.logger.info("Saving \(leftOverRequests.count) requests.")

				CloudKitActionRequest.save(requests: leftOverRequests)
				self.deleteTempFiles(tempFileURLs)
				
				DispatchQueue.main.async {
					self.operationDelegate?.operationDidComplete(self)
				}
			}
		}
	}
	
	func loadAndStageEntities(requests: Set<CloudKitActionRequest>) -> ([Document], [URL]) {
		var loadedDocuments = [Document]()
		var tempFileURLs = [URL]()
		let combinedRequests = combine(requests: requests)

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
			for rowRequest in combinedRequest.rowRequests {
				if let row = outline.findRow(id: rowRequest.id.rowUUID) {
					outline.updateRowSyncID(row)
					addSave(zoneID, row.buildClientRecord())
				} else {
					addDelete(rowRequest)
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
		
		return (loadedDocuments, tempFileURLs)
	}
	
	func combine(requests: Set<CloudKitActionRequest>) -> [String: CombinedRequest] {
		var combinedRequests = [String: CombinedRequest]()

		for request in requests {
			switch request.id {
			case .document(_, let documentUUID):
				if let combinedRequest = combinedRequests[documentUUID] {
					combinedRequest.documentRequest = request
					combinedRequests[documentUUID] = combinedRequest
				} else {
					let combinedRequest = CombinedRequest()
					combinedRequest.documentRequest = request
					combinedRequests[documentUUID] = combinedRequest
				}
			case .row(_, let documentUUID, _):
				if let combinedRequest = combinedRequests[documentUUID] {
					combinedRequest.rowRequests.append(request)
					combinedRequests[documentUUID] = combinedRequest
				} else {
					let combinedRequest = CombinedRequest()
					combinedRequest.rowRequests.append(request)
					combinedRequests[documentUUID] = combinedRequest
				}
			case .image(_, let documentUUID, _, _):
				if let combinedRequest = combinedRequests[documentUUID] {
					combinedRequest.imageRequests.append(request)
					combinedRequests[documentUUID] = combinedRequest
				} else {
					let combinedRequest = CombinedRequest()
					combinedRequest.imageRequests.append(request)
					combinedRequests[documentUUID] = combinedRequest
				}
			default:
				fatalError()
			}
		}
		
		return combinedRequests
	}
	
	func updateSyncMetaData(savedRecords: [CKRecord]) {
		for savedRecord in savedRecords {
			guard let entityID = EntityID(description: savedRecord.recordID.recordName),
					let outline = account.findDocument(entityID)?.outline else { continue }
			
			switch savedRecord.recordType {
			case "Outline":
				outline.cloudKitMetaData = savedRecord.metadata
			case "Row":
				(outline.findRowContainer(entityID: entityID) as? Row)?.cloudKitMetaData = savedRecord.metadata
			case "Image":
				(outline.findRowContainer(entityID: entityID) as? Row)?.findImage(id: entityID)?.cloudKitMetaData = savedRecord.metadata
			default:
				break
			}
		}
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
			if let syncMetaData = outline.cloudKitMetaData, let record = CKRecord(syncMetaData) {
				return record
			} else {
				let recordID = CKRecord.ID(recordName: outline.id.description, zoneID: zoneID)
				return CKRecord(recordType: Outline.CloudKitRecord.recordType, recordID: recordID)
			}
		}()
		
		record[Outline.CloudKitRecord.Fields.syncID] = outline.syncID
		record[Outline.CloudKitRecord.Fields.title] = outline.title
		record[Outline.CloudKitRecord.Fields.ownerName] = outline.ownerName
		record[Outline.CloudKitRecord.Fields.ownerEmail] = outline.ownerEmail
		record[Outline.CloudKitRecord.Fields.ownerURL] = outline.ownerURL
		record[Outline.CloudKitRecord.Fields.created] = outline.created
		record[Outline.CloudKitRecord.Fields.updated] = outline.updated
		record[Outline.CloudKitRecord.Fields.tagNames] = outline.tags.map { $0.name }
		if let rowOrder = outline.rowOrder {
			record[Outline.CloudKitRecord.Fields.rowOrder] = Array(rowOrder)
		}
		record[Outline.CloudKitRecord.Fields.documentLinks] = outline.documentLinks?.map { $0.description }
		record[Outline.CloudKitRecord.Fields.documentBacklinks] = outline.documentBacklinks?.map { $0.description }
		record[Outline.CloudKitRecord.Fields.hasAltLinks] = outline.hasAltLinks
		record[Outline.CloudKitRecord.Fields.disambiguator] = outline.disambiguator

		addSave(zoneID, record)
	}
	
	func addSave(zoneID: CKRecordZone.ID, image: Image) -> URL {
		let record: CKRecord = {
			if let syncMetaData = image.cloudKitMetaData, let record = CKRecord(syncMetaData) {
				return record
			} else {
				let recordID = CKRecord.ID(recordName: image.id.description, zoneID: zoneID)
				return CKRecord(recordType: Image.CloudKitRecord.recordType, recordID: recordID)
			}
		}()
		
		let rowID = EntityID.row(image.id.accountID, image.id.documentUUID, image.id.rowUUID)
		let rowRecordID = CKRecord.ID(recordName: rowID.description, zoneID: zoneID)
		
		record.parent = CKRecord.Reference(recordID: rowRecordID, action: .none)
		record[Image.CloudKitRecord.Fields.row] = CKRecord.Reference(recordID: rowRecordID, action: .deleteSelf)
		record[Image.CloudKitRecord.Fields.isInNotes] = image.isInNotes
		record[Image.CloudKitRecord.Fields.offset] = image.offset
		record[Image.CloudKitRecord.Fields.syncID] = image.syncID

		let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent(image.id.imageUUID).appendingPathExtension("png")
		try? image.data.write(to: imageURL)
		record[Image.CloudKitRecord.Fields.asset] = CKAsset(fileURL: imageURL)

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

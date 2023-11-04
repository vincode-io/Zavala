//
//  Outline+Cloudkit.swift
//  
//
//  Created by Maurice Parker on 3/15/23.
//

import Foundation
import CloudKit
import OrderedCollections
import VinCloudKit

extension Outline {
	
	struct CloudKitRecord {
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

	func beginCloudKitBatchRequest() {
		batchCloudKitRequests += 1
	}
	
	func requestCloudKitUpdateForSelf() {
		requestCloudKitUpdate(for: id)
	}
	
	func requestCloudKitUpdate(for entityID: EntityID) {
		guard let cloudKitManager = account?.cloudKitManager else { return }
		if batchCloudKitRequests > 0 {
			cloudKitRequestsIDs.insert(entityID)
		} else {
			guard let zoneID = zoneID else { return }
			cloudKitManager.addRequest(CloudKitActionRequest(zoneID: zoneID, id: entityID))
		}
	}

	func requestCloudKitUpdates(for entityIDs: [EntityID]) {
		for id in entityIDs {
			requestCloudKitUpdate(for: id)
		}
	}

	func endCloudKitBatchRequest() {
		batchCloudKitRequests = batchCloudKitRequests - 1
		guard batchCloudKitRequests == 0, let cloudKitManager = account?.cloudKitManager, let zoneID = zoneID else { return }

		let requests = cloudKitRequestsIDs.map { CloudKitActionRequest(zoneID: zoneID, id: $0) }
		cloudKitManager.addRequests(Set(requests))
	}

	func apply(_ update: CloudKitOutlineUpdate) {
		var updatedRowIDs = Set<String>()
		
		if let record = update.saveOutlineRecord {
			let outlineUpdatedRows = applyOutlineRecord(record)
			updatedRowIDs.formUnion(outlineUpdatedRows)
		}
		
		if keyedRows == nil {
			keyedRows = [String: Row]()
		}
		
		for deleteRecordID in update.deleteRowRecordIDs {
			keyedRows?.removeValue(forKey: deleteRecordID.rowUUID)
		}
		
		for saveRecord in update.saveRowRecords {
			guard let entityID = EntityID(description: saveRecord.recordID.recordName) else { continue }

			var isExistingRecord = false
			var row: Row
			if let existingRow = keyedRows?[entityID.rowUUID] {
				row = existingRow
				isExistingRecord = true
			} else {
				row = Row(id: entityID.rowUUID)
			}

			if let recordSyncID = saveRecord[Row.CloudKitRecord.Fields.syncID] as? String, recordSyncID == row.syncID {
				continue
			}

			row.cloudKitMetaData = saveRecord.metadata
			
			if isExistingRecord {
				updatedRowIDs.insert(row.id)
			}
			
			row.apply(saveRecord)
			keyedRows?[entityID.rowUUID] = row
		}
		
		for deleteRecordID in update.deleteImageRecordIDs {
			if let row = keyedRows?[deleteRecordID.rowUUID] {
				if row.findImage(id: deleteRecordID) != nil {
					row.deleteImage(id: deleteRecordID)
					updatedRowIDs.insert(deleteRecordID.rowUUID)
				}
			}
		}
		
		for saveRecord in update.saveImageRecords {
			guard let saveRecordID = EntityID(description: saveRecord.recordID.recordName),
				  let row = keyedRows?[saveRecordID.rowUUID] else { continue }
			
			if let syncID = saveRecord[Image.CloudKitRecord.Fields.syncID] as? String,
			   let image = row.findImage(id: saveRecordID),
			   image.syncID == syncID {
				continue
			}
			
			if let isInNotes = saveRecord[Image.CloudKitRecord.Fields.isInNotes] as? Bool,
			   let offset = saveRecord[Image.CloudKitRecord.Fields.offset] as? Int,
			   let asset = saveRecord[Image.CloudKitRecord.Fields.asset] as? CKAsset,
			   let fileURL = asset.fileURL,
			   let data = try? Data(contentsOf: fileURL) {

				let image = Image(id: saveRecordID, isInNotes: isInNotes, offset: offset, data: data)
				image.cloudKitMetaData = saveRecord.metadata
				
				row.saveImage(image)
				updatedRowIDs.insert(saveRecordID.rowUUID)
			}
		}
		
		if !updatedRowIDs.isEmpty {
			rowsFile?.markAsDirty()
			documentDidChangeBySync()
		}
		
		guard isBeingUsed else { return }

		var reloadRows = [Row]()
		
		func reloadVisitor(_ visited: Row) {
			reloadRows.append(visited)
			visited.rows.forEach { $0.visit(visitor: reloadVisitor) }
		}

		for updatedRowID in updatedRowIDs {
			if let updatedRow = keyedRows?[updatedRowID] {
				reloadRows.append(updatedRow)
				updatedRow.rows.forEach { $0.visit(visitor: reloadVisitor(_:)) }
			}
		}
		
		var changes = rebuildShadowTable()
		let reloadIndexes = reloadRows.compactMap { $0.shadowTableIndex }
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloadIndexes)))
		
		if !changes.isEmpty {
			outlineElementsDidChange(changes)
		}
	}
	
	private func applyOutlineRecord(_ record: CKRecord) -> [String] {
		if let shareReference = record.share {
			cloudKitShareRecordName = shareReference.recordID.recordName
		} else {
			cloudKitShareRecordName = nil
		}

		if let recordSyncID = record[Outline.CloudKitRecord.Fields.syncID] as? String, recordSyncID == syncID {
			return []
		}
		
		cloudKitMetaData = record.metadata
		
		let newTitle = record[Outline.CloudKitRecord.Fields.title] as? String
		if title != newTitle {
			title = newTitle
			if isBeingUsed {
				outlineElementsDidChange(OutlineElementChanges(section: .title, reloads: Set([0])))
			}
		}

		ownerName = record[Outline.CloudKitRecord.Fields.ownerName] as? String
		ownerEmail = record[Outline.CloudKitRecord.Fields.ownerEmail] as? String
		ownerURL = record[Outline.CloudKitRecord.Fields.ownerURL] as? String
		created = record[Outline.CloudKitRecord.Fields.created] as? Date
		updated = record[Outline.CloudKitRecord.Fields.updated] as? Date
		hasAltLinks = record[Outline.CloudKitRecord.Fields.hasAltLinks] as? Bool
		disambiguator = record[Outline.CloudKitRecord.Fields.disambiguator] as? Int

		let newRowOrder: OrderedSet<String>
		if let cloudKitRowOrder = record[Outline.CloudKitRecord.Fields.rowOrder] as? [String] {
			newRowOrder = OrderedSet(cloudKitRowOrder)
		} else {
			newRowOrder = OrderedSet<String>()
		}
		
		var updatedRowIDs = [String]()
		
		//  We only count newly added children for reloading so that they can indent or outdent
		let rowDiff = newRowOrder.difference(from: rowOrder ?? OrderedSet<String>())
		for change in rowDiff {
			switch change {
			case .insert(_, let newRowID, _):
				updatedRowIDs.append(newRowID)
			default:
				break
			}
		}

		rowOrder = newRowOrder

		let documentLinkDescriptions = record[Outline.CloudKitRecord.Fields.documentLinks] as? [String] ?? [String]()
		documentLinks = documentLinkDescriptions.compactMap { EntityID(description: $0) }

		let documentBacklinkDescriptions = record[Outline.CloudKitRecord.Fields.documentBacklinks] as? [String] ?? [String]()
		let cloudKitBackLinks = documentBacklinkDescriptions.compactMap { EntityID(description: $0) }

		for backlink in Set(cloudKitBackLinks).subtracting(documentBacklinks ?? [EntityID]()) {
			createBacklink(backlink)
		}

		for backlink in Set(documentBacklinks ?? [EntityID]()).subtracting(cloudKitBackLinks) {
			deleteBacklink(backlink)
		}

		let cloudKitTagNames = record[Outline.CloudKitRecord.Fields.tagNames] as? [String] ?? [String]()
		let currentTagNames = Set(tags.map { $0.name })
		
		guard let account = account else { return updatedRowIDs }

		let cloudKitTagIDs = cloudKitTagNames.map({ account.createTag(name: $0) }).map({ $0.id })
		let oldTagIDs = tagIDs ?? [String]()
		tagIDs = cloudKitTagIDs

		let tagNamesToDelete = currentTagNames.subtracting(cloudKitTagNames)
		for tagNameToDelete in tagNamesToDelete {
			account.deleteTag(name: tagNameToDelete)
		}
		
		guard isBeingUsed, isSearching == .notSearching else { return updatedRowIDs }

		var moves = Set<OutlineElementChanges.Move>()
		var inserts = Set<Int>()
		var deletes = Set<Int>()
		
		let tagDiff = cloudKitTagIDs.difference(from: oldTagIDs).inferringMoves()
		for change in tagDiff {
			switch change {
			case .insert(let offset, _, let associated):
				if let associated = associated {
					moves.insert(OutlineElementChanges.Move(associated, offset))
				} else {
					inserts.insert(offset)
				}
			case .remove(let offset, _, let associated):
				if let associated = associated {
					moves.insert(OutlineElementChanges.Move(offset, associated))
				} else {
					deletes.insert(offset)
				}
			}
		}
		
		let changes = OutlineElementChanges(section: .tags, deletes: deletes, inserts: inserts, moves: moves)
		outlineElementsDidChange(changes)
		
		return updatedRowIDs
	}
	
}

// MARK: CloudKitModel

//extension Outline {
//
//	public func resolveConflict(_: CKError) throws -> CKRecord {
//		let ancestorRecord = buildAncestorRecord()
//
//		try ckError.merge(key: "syncID", fieldType: String.self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "title", fieldType: String.self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "ownerName", fieldType: String.self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "ownerEmail", fieldType: String.self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "ownerURL", fieldType: String.self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "created", fieldType: Date.self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "updated", fieldType: Date.self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "tagNames", fieldType: [String].self, ancestorRecord: ancestorRecord)
//		try ckError.mergeArray(key: "rowOrder", fieldType: [String].self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "documentLinks", fieldType: [String].self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "documentBacklinks", fieldType: [String].self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "hasAltLinks", fieldType: Bool.self, ancestorRecord: ancestorRecord)
//		try ckError.merge(key: "disambiguator", fieldType: Int.self, ancestorRecord: ancestorRecord)
//
//		return ckError.serverRecord!
//	}
//	
//}

// MARK: Helpers

private extension Outline {
	
	func documentDidChangeBySync() {
		NotificationCenter.default.post(name: .DocumentDidChangeBySync, object: Document.outline(self), userInfo: nil)
	}

}

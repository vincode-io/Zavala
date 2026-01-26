//
//  Row+CloudKit.swift
//
//
//  Created by Maurice Parker on 3/15/23.
//

import Foundation
import CloudKit
import OrderedCollections
import VinCloudKit

extension Row: VCKModel {

	struct CloudKitRecord {
		static let recordType = "Row"
		struct Fields {
			static let outline = "outline"
			static let subtype = "subtype"
			static let topicData = "topicData"
			static let noteData = "noteData"
			static let isComplete = "isComplete"
			static let rowOrder = "rowOrder" // Deprecated, kept for backward compatibility
			static let order = "order"       // Fractional indexing order
			static let parentRowID = "parentRowID" // Parent row ID (nil = parent is Outline)
		}
	}

	public var cloudKitRecordID: CKRecord.ID {
		guard let zoneID = outline?.zoneID else { fatalError("Missing Outline in Row.") }
		return CKRecord.ID(recordName: entityID.description, zoneID: zoneID)
	}

	public func apply(_ record: CKRecord) -> Bool {
		if let metaData = cloudKitMetaData,
		   let recordChangeTag = CKRecord(metaData)?.recordChangeTag,
		   record.recordChangeTag == recordChangeTag {
			return false
		}

		cloudKitMetaData = record.metadata

		var updated = false

		// Handle legacy rowOrder field
		if let serverRowOrder = record[Row.CloudKitRecord.Fields.rowOrder] as? [String] {
			let serverRowOrderedSet = OrderedSet(serverRowOrder)
			if serverRowOrderedSet != rowOrder {
				updated = true
				rowOrder = serverRowOrderedSet
			}
		} else {
			rowOrder = OrderedSet<String>()
		}

		// Handle fractional indexing order field
		if let serverOrderValue = record[Row.CloudKitRecord.Fields.order] as? String {
			if serverOrderValue != order {
				updated = true
				order = serverOrderValue
			}
		}

		// Handle parentRowID field
		let serverParentIDValue = record[Row.CloudKitRecord.Fields.parentRowID] as? String
		if serverParentIDValue != parentID {
			updated = true
			parentID = serverParentIDValue
		}

		let serverIsComplete = record[Row.CloudKitRecord.Fields.isComplete] as? String == "1" ? true : false
		if serverIsComplete != isComplete {
			updated = true
			isComplete = serverIsComplete
		}

		let serverTopicData = record[Row.CloudKitRecord.Fields.topicData] as? Data
		if serverTopicData != topicData {
			updated = true
			topicData = serverTopicData
		}

		let serverNoteData = record[Row.CloudKitRecord.Fields.noteData] as? Data
		if serverNoteData != noteData {
			updated = true
			noteData = serverNoteData
		}

		clearSyncData()

		return updated
	}

	public func apply(_ error: CKError) {
		guard let record = error.serverRecord else { return }
		cloudKitMetaData = record.metadata

		if let errorRowOrder = record[Row.CloudKitRecord.Fields.rowOrder] as? [String] {
			serverRowOrder = OrderedSet(errorRowOrder)
		} else {
			serverRowOrder = nil
		}

		// Capture server values for fractional indexing fields
		serverOrder = record[Row.CloudKitRecord.Fields.order] as? String
		serverParentID = record[Row.CloudKitRecord.Fields.parentRowID] as? String

		serverIsComplete = record[Row.CloudKitRecord.Fields.isComplete] as? String == "1" ? true : false
		serverTopicData = record[Row.CloudKitRecord.Fields.topicData] as? Data
		serverNoteData = record[Row.CloudKitRecord.Fields.noteData] as? Data

		isCloudKitMerging = true
	}

	public func buildRecord() -> CKRecord? {
		guard let zoneID = outline?.zoneID, let parent else {
			return nil
		}

		let parentRecordName: String = if let parentRow = parent as? Row {
			parentRow.entityID.description
		} else {
			(parent as! Outline).id.description
		}

		let record: CKRecord = {
			if let syncMetaData = cloudKitMetaData, let record = CKRecord(syncMetaData) {
				return record
			} else {
				return CKRecord(recordType: Row.CloudKitRecord.recordType, recordID: cloudKitRecordID)
			}
		}()

		let parentRecordID = CKRecord.ID(recordName: parentRecordName, zoneID: zoneID)
		record.parent = CKRecord.Reference(recordID: parentRecordID, action: .none)

		record[Row.CloudKitRecord.Fields.outline] = CKRecord.Reference(recordID: parentRecordID, action: .deleteSelf)
		record[Row.CloudKitRecord.Fields.subtype] = "text"

		// Write legacy rowOrder (empty for backward compatibility with older clients)
		let recordRowOrder = merge(client: rowOrder, ancestor: ancestorRowOrder, server: serverRowOrder)
		record[Row.CloudKitRecord.Fields.rowOrder] = Array(recordRowOrder)

		// Write fractional indexing order with three-way merge
		let recordOrder = merge(client: order, ancestor: ancestorOrder, server: serverOrder) ?? ""
		record[Row.CloudKitRecord.Fields.order] = recordOrder

		// Write parentRowID with three-way merge
		let recordParentID = merge(client: parentID, ancestor: ancestorParentID, server: serverParentID)
		record[Row.CloudKitRecord.Fields.parentRowID] = recordParentID

		let recordIsComplete = merge(client: isComplete, ancestor: ancestorIsComplete, server: serverIsComplete) ?? false
		record[Row.CloudKitRecord.Fields.isComplete] = recordIsComplete ? "1" : "0"

		let topicString = topicData?.toAttributedString()
		let ancestorTopicString = ancestorTopicData?.toAttributedString()
		let serverTopicString = serverTopicData?.toAttributedString()

		let recordTopicString = merge(client: topicString, ancestor: ancestorTopicString, server: serverTopicString)
		record[Row.CloudKitRecord.Fields.topicData] = recordTopicString?.toData()

		let noteString = noteData?.toAttributedString()
		let ancestorNoteString = ancestorNoteData?.toAttributedString()
		let serverNoteString = serverNoteData?.toAttributedString()

		let recordNoteString = merge(client: noteString, ancestor: ancestorNoteString, server: serverNoteString)
		record[Row.CloudKitRecord.Fields.noteData] = recordNoteString?.toData()

		return record
	}

	public func clearSyncData() {
		isCloudKitMerging = false

		ancestorRowOrder = nil
		serverRowOrder = nil

		ancestorOrder = nil
		serverOrder = nil

		ancestorParentID = nil
		serverParentID = nil

		ancestorIsComplete = nil
		serverIsComplete = nil

		ancestorTopicData = nil
		serverTopicData = nil

		ancestorNoteData = nil
		serverNoteData = nil
	}

}

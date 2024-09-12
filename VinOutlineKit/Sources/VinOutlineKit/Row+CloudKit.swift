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
			static let rowOrder = "rowOrder"
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
		
		if let serverRowOrder = record[Row.CloudKitRecord.Fields.rowOrder] as? [String] {
			let serverRowOrderedSet = OrderedSet(serverRowOrder)
			if serverRowOrderedSet != rowOrder {
				updated = true
				rowOrder = serverRowOrderedSet
			}
		} else {
			rowOrder = OrderedSet<String>()
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

		serverIsComplete = record[Row.CloudKitRecord.Fields.isComplete] as? String == "1" ? true : false
		serverTopicData = record[Row.CloudKitRecord.Fields.topicData] as? Data
		serverNoteData = record[Row.CloudKitRecord.Fields.noteData] as? Data

		isCloudKitMerging = true
	}
	
	public func buildRecord() -> CKRecord {
		guard let zoneID = outline?.zoneID else {
			fatalError("There is not enough associated CloudKit information for this object.")
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
		
		let recordRowOrder = merge(client: rowOrder, ancestor: ancestorRowOrder, server: serverRowOrder)
		record[Row.CloudKitRecord.Fields.rowOrder] = Array(recordRowOrder)
		
		let recordIsComplete = merge(client: isComplete, ancestor: ancestorIsComplete, server: serverIsComplete)
		record[Row.CloudKitRecord.Fields.isComplete] = recordIsComplete! ? "1" : "0"
		
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
		
		ancestorIsComplete = nil
		serverIsComplete = nil
		
		ancestorTopicData = nil
		serverTopicData = nil
		
		ancestorNoteData = nil
		serverNoteData = nil
	}

}

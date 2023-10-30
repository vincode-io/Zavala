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

extension Row: CloudKitModel {
	
	public var cloudKitRecordID: CKRecord.ID {
		guard let zoneID = outline?.zoneID else { fatalError("Missing Zone ID for CloudKit row record.") }
		return CKRecord.ID(recordName: entityID.description, zoneID: zoneID)
	}
	
	struct CloudKitRecord {
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

	public func buildClientRecord() -> CKRecord {
		guard let zoneID = outline?.zoneID,
			  let outlineRecordName = outline?.id.description
		else {
			fatalError("There is note enough associated CloudKit information for this object.")
		}
		
		let record: CKRecord = {
			if let syncMetaData = cloudKitMetaData, let record = CKRecord(syncMetaData) {
				return record
			} else {
				return CKRecord(recordType: Row.CloudKitRecord.recordType, recordID: cloudKitRecordID)
			}
		}()

		let outlineRecordID = CKRecord.ID(recordName: outlineRecordName, zoneID: zoneID)
		record.parent = CKRecord.Reference(recordID: outlineRecordID, action: .none)
		
		record[Row.CloudKitRecord.Fields.outline] = CKRecord.Reference(recordID: outlineRecordID, action: .deleteSelf)
		record[Row.CloudKitRecord.Fields.subtype] = "text"
		record[Row.CloudKitRecord.Fields.syncID] = syncID
		record[Row.CloudKitRecord.Fields.rowOrder] = Array(rowOrder)
		record[Row.CloudKitRecord.Fields.isComplete] = isComplete ? "1" : "0"
		record[Row.CloudKitRecord.Fields.topicData] = topicData
		record[Row.CloudKitRecord.Fields.noteData] = noteData
		
		return record
	}
	
	public func buildAncestorRecord() -> CKRecord {
		let record = buildClientRecord();
		
		if let syncIDCloudKitValue {
			record[Row.CloudKitRecord.Fields.syncID] = syncIDCloudKitValue
		}
		
		if let rowOrderCloudKitValue {
			record[Row.CloudKitRecord.Fields.rowOrder] = Array(rowOrderCloudKitValue)
		}

		if let isCompleteCloudKitValue {
			record[Row.CloudKitRecord.Fields.isComplete] = isCompleteCloudKitValue ? "1" : "0"
		}

		if let topicData {
			record[Row.CloudKitRecord.Fields.isComplete] = topicData
		}

		if let noteData {
			record[Row.CloudKitRecord.Fields.isComplete] = noteData
		}

		return record
	}

	public func apply(_ record: CKRecord) {
		let updatedTopicData = record[Row.CloudKitRecord.Fields.topicData] as? Data
		topicData = updatedTopicData
		
		let updatedNoteData = record[Row.CloudKitRecord.Fields.noteData] as? Data
		noteData = updatedNoteData
		
		let updatedIsComplete = record[Row.CloudKitRecord.Fields.isComplete] as? String == "1" ? true : false
		isComplete = updatedIsComplete
		
		if let newRowOrder = record[Row.CloudKitRecord.Fields.rowOrder] as? [String] {
			rowOrder = OrderedSet(newRowOrder)
		} else {
			rowOrder = OrderedSet<String>()
		}
	}
	
	public func clearAncestorData() {
		syncIDCloudKitValue = nil
		rowOrderCloudKitValue = nil
		isCompleteCloudKitValue = nil
		topicDataCloudKitValue = nil
		noteDataCloudkitValue = nil
	}

}

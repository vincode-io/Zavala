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

extension Row {
	
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
	
}

// MARK: CloudKitModel

extension Row: VCKModel {

	public var cloudKitRecordID: CKRecord.ID {
		guard let zoneID = outline?.zoneID else { fatalError("Missing Outline in Row.") }
		return CKRecord.ID(recordName: entityID.description, zoneID: zoneID)
	}
	
	public func apply(_ record: CKRecord) {
		cloudKitMetaData = record.metadata

		let serverSyncID = record[Row.CloudKitRecord.Fields.syncID] as? String
		syncID = merge(client: syncID, ancestor: ancestorSyncID, server: serverSyncID)

		if let newRowOrder = record[Row.CloudKitRecord.Fields.rowOrder] as? [String] {
			rowOrder = merge(client: rowOrder, ancestor: ancestorRowOrder, server: OrderedSet(newRowOrder))
		} else {
			rowOrder = OrderedSet<String>()
		}

		let serverIsComplete = record[Row.CloudKitRecord.Fields.isComplete] as? String == "1" ? true : false
		isComplete = merge(client: isComplete, ancestor: ancestorIsComplete, server: serverIsComplete)!
		
		let serverTopicData = record[Row.CloudKitRecord.Fields.topicData] as? Data
		topicData = merge(client: topicData, ancestor: ancestorTopicData, server: serverTopicData)
		
		let serverNoteData = record[Row.CloudKitRecord.Fields.noteData] as? Data
		noteData = merge(client: noteData, ancestor: ancestorNoteData, server: serverNoteData)
	}
	
	public func apply(_ error: CKError) {
		guard let record = error.serverRecord else { return }
		
		serverSyncID = record[Row.CloudKitRecord.Fields.syncID] as? String

		if let newRowOrder = record[Row.CloudKitRecord.Fields.rowOrder] as? [String] {
			serverRowOrder = OrderedSet(newRowOrder)
		} else {
			serverRowOrder = OrderedSet<String>()
		}

		serverIsComplete = record[Row.CloudKitRecord.Fields.isComplete] as? String == "1" ? true : false
		serverTopicData = record[Row.CloudKitRecord.Fields.topicData] as? Data
		serverNoteData = record[Row.CloudKitRecord.Fields.noteData] as? Data
	}
	
	public func buildRecord() -> CKRecord {
		guard let zoneID = outline?.zoneID,
			  let outlineRecordName = outline?.id.description
		else {
			fatalError("There is not enough associated CloudKit information for this object.")
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
		
		let recordSyncID = merge(client: syncID, ancestor: ancestorSyncID, server: serverSyncID)
		record[Row.CloudKitRecord.Fields.syncID] = recordSyncID
		
		let recordRowOrder = merge(client: rowOrder, ancestor: ancestorRowOrder, server: serverRowOrder)
		record[Row.CloudKitRecord.Fields.rowOrder] = Array(recordRowOrder)
		
		let recordIsComplete = merge(client: isComplete, ancestor: ancestorIsComplete, server: serverIsComplete)
		record[Row.CloudKitRecord.Fields.isComplete] = recordIsComplete! ? "1" : "0"
		
		let recordTopicData = merge(client: topicData, ancestor: ancestorTopicData, server: serverTopicData)
		record[Row.CloudKitRecord.Fields.topicData] = recordTopicData
		
		let recordNoteData = merge(client: noteData, ancestor: ancestorNoteData, server: serverNoteData)
		record[Row.CloudKitRecord.Fields.noteData] = recordNoteData
		
		return record
	}

	public func deleteTempFiles() { }

	public func clearSyncData() {
		ancestorSyncID = nil
		serverSyncID = nil
		
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

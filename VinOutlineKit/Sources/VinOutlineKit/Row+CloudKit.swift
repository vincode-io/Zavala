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
			static let syncID = "syncID"
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
	
	public func apply(_ record: CKRecord) {
		cloudKitMetaData = record.metadata
		syncID = record[Row.CloudKitRecord.Fields.syncID] as? String

		if let serverRowOrder = record[Row.CloudKitRecord.Fields.rowOrder] as? [String] {
			rowOrder = merge(client: rowOrder, ancestor: ancestorRowOrder, server: OrderedSet(serverRowOrder))
		} else {
			rowOrder = OrderedSet<String>()
		}

		let serverIsComplete = record[Row.CloudKitRecord.Fields.isComplete] as? String == "1" ? true : false
		isComplete = merge(client: isComplete, ancestor: ancestorIsComplete, server: serverIsComplete)!
		
		let serverTopicData = record[Row.CloudKitRecord.Fields.topicData] as? Data
		topicData = merge(client: topicData, ancestor: ancestorTopicData, server: serverTopicData)
		
		let serverNoteData = record[Row.CloudKitRecord.Fields.noteData] as? Data
		noteData = merge(client: noteData, ancestor: ancestorNoteData, server: serverNoteData)
        
        clearSyncData()
	}
	
	public func apply(_ error: CKError) {
		guard let record = error.serverRecord else { return }
		
		mergeSyncID = UUID().uuidString

		if let errorRowOrder = record[Row.CloudKitRecord.Fields.rowOrder] as? [String] {
			serverRowOrder = OrderedSet(errorRowOrder)
		} else {
			serverRowOrder = nil
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
		
		record[Row.CloudKitRecord.Fields.syncID] = mergeSyncID ?? syncID
		
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

	public func clearSyncData() {
		mergeSyncID = nil
		
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

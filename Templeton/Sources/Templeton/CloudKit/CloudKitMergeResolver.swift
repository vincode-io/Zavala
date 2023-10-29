//
//  CloudKitMergeResolver.swift
//  
//
//  Created by Maurice Parker on 11/1/22.
//

import Foundation
import CloudKit
import RSCore
import VinCloudKit

struct CloudKitMergeResolver: CloudKitConflictResolver {
	
	var modelsToSave: [CloudKitModel]?
	
	func resolve(_ refinedResult: CloudKitResult) throws -> [CKRecord] {
		guard let modelsToSave else { fatalError() }
		
		switch refinedResult {
		case .serverRecordChanged(let ckError):
			return [try resolve(ckError, ancestorRecord: modelsToSave[0].buildAncestorRecord())]
			
		case .partialFailure(let ckError):
			
			return try modelsToSave.compactMap { modelToSave in
				guard let ckErrorForRecord = ckError.partialErrorsByItemID?[modelToSave.cloudKitRecordID] as? CKError else {
					return nil
				}
				
				guard ckErrorForRecord.code != .batchRequestFailed else {
					return ckErrorForRecord.clientRecord
				}
				
				return try resolve(ckErrorForRecord, ancestorRecord: modelToSave.buildAncestorRecord())
			}
			
		default:
			fatalError("We should never have gotten here.")
		}
	}
	
}

private extension CloudKitMergeResolver {
	
	#warning("Desk check these again and change the keys so that they reference the actual record...")
	func resolve(_ ckError: CKError, ancestorRecord: CKRecord) throws -> CKRecord {
		switch ckError.ancestorRecord?.recordType {
		case Outline.CloudKitRecord.recordType:
			try ckError.merge(key: "syncID", fieldType: String.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "title", fieldType: String.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "ownerName", fieldType: String.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "ownerEmail", fieldType: String.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "ownerURL", fieldType: String.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "created", fieldType: Date.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "updated", fieldType: Date.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "tagNames", fieldType: [String].self, ancestorRecord: ancestorRecord)
			try ckError.mergeArray(key: "rowOrder", fieldType: [String].self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "documentLinks", fieldType: [String].self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "documentBacklinks", fieldType: [String].self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "hasAltLinks", fieldType: Bool.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "disambiguator", fieldType: Int.self, ancestorRecord: ancestorRecord)
		case Row.CloudKitRecord.recordType:
			try ckError.merge(key: Row.CloudKitRecord.Fields.syncID, fieldType: String.self, ancestorRecord: ancestorRecord)
			try ckError.mergeArray(key: Row.CloudKitRecord.Fields.rowOrder, fieldType: [String].self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: Row.CloudKitRecord.Fields.isComplete, fieldType: Bool.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: Row.CloudKitRecord.Fields.topicData, fieldType: Data.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: Row.CloudKitRecord.Fields.noteData, fieldType: Data.self, ancestorRecord: ancestorRecord)
		case Image.CloudKitRecord.recordType:
			try ckError.merge(key: "syncID", fieldType: String.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "isInNotes", fieldType: Bool.self, ancestorRecord: ancestorRecord)
			try ckError.merge(key: "offset", fieldType: Int.self, ancestorRecord: ancestorRecord)
		default:
			fatalError()
		}
		
		return ckError.serverRecord!
	}

}



//		let serverKeyDiff = serverRecord.allKeys().difference(from: ancestorRecord.allKeys())
//		var serverAddedKeys = serverKeyDiff.insertedElements
//		var serverDeletedKeys = serverKeyDiff.removeElements

//private extension CollectionDifference {
//
//	var insertedElements: [ChangeElement] {
//		return insertions.map { $0.element }
//	}
//
//	var removeElements: [ChangeElement] {
//		return removals.map { $0.element }
//	}
//
//}
//
//private extension CollectionDifference.Change {
//
//	var element: ChangeElement {
//		switch self {
//		case .insert(_, let element, _), .remove(_, let element, _):
//			return element
//		}
//	}
//
//}

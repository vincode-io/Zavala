//
//  CloudKitMergeResolver.swift
//  
//
//  Created by Maurice Parker on 11/1/22.
//

import Foundation
import CloudKit
import RSCore

struct CloudKitMergeResolver: CloudKitConflictResolver, Logging {
	
	var recordsToSave: [CKRecord]?
	
	func resolve(_ refinedResult: CloudKitResult) throws -> [CKRecord] {
		switch refinedResult {
		case .serverRecordChanged(let ckError):
			return [try resolve(ckError)]
			
		case .partialFailure(let ckError):
			guard let recordsToSave else { return [] }
			
			return try recordsToSave.compactMap { recordToSave in
				guard let ckErrorForRecord = ckError.partialErrorsByItemID?[recordToSave.recordID] as? CKError else {
					return nil
				}
				
				guard ckErrorForRecord.code != .batchRequestFailed else {
					return recordToSave
				}
				
				return try resolve(ckErrorForRecord)
			}
			
		default:
			fatalError("We should never have gotten here.")
		}
	}
	
}

private extension CloudKitMergeResolver {
	
	#warning("Desk check these again and change the keys so that they reference the actual record...")
	func resolve(_ ckError: CKError) throws -> CKRecord {
		switch ckError.ancestorRecord?.recordType {
		case Outline.CloudKitRecord.recordType:
			try ckError.merge(key: "syncID", fieldType: String.self)
			try ckError.merge(key: "title", fieldType: String.self)
			try ckError.merge(key: "ownerName", fieldType: String.self)
			try ckError.merge(key: "ownerEmail", fieldType: String.self)
			try ckError.merge(key: "ownerURL", fieldType: String.self)
			try ckError.merge(key: "created", fieldType: Date.self)
			try ckError.merge(key: "updated", fieldType: Date.self)
			try ckError.merge(key: "tagNames", fieldType: [String].self)
			try ckError.mergeArray(key: "rowOrder", fieldType: [String].self)
			try ckError.merge(key: "documentLinks", fieldType: [String].self)
			try ckError.merge(key: "documentBacklinks", fieldType: [String].self)
			try ckError.merge(key: "hasAltLinks", fieldType: Bool.self)
			try ckError.merge(key: "disambiguator", fieldType: Int.self)
		case Row.CloudKitRecord.recordType:
			try ckError.merge(key: "syncID", fieldType: String.self)
			try ckError.merge(key: "subtype", fieldType: String.self)
			try ckError.merge(key: "topicData", fieldType: Data.self)
			try ckError.merge(key: "noteData", fieldType: Data.self)
			try ckError.merge(key: "isComplete", fieldType: Bool.self)
			try ckError.mergeArray(key: "rowOrder", fieldType: [String].self)
		case Image.CloudKitRecord.recordType:
			try ckError.merge(key: "syncID", fieldType: String.self)
			try ckError.merge(key: "isInNotes", fieldType: Bool.self)
			try ckError.merge(key: "offset", fieldType: Int.self)
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

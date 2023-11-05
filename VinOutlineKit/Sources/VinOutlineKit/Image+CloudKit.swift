//
//  Image+CloudKit.swift
//  
//
//  Created by Maurice Parker on 3/15/23.
//

import Foundation
import CloudKit
import VinCloudKit

extension Image {
	
	struct CloudKitRecord {
		static let recordType = "Image"
		struct Fields {
			static let syncID = "syncID"
			static let row = "row"
			static let isInNotes = "isInNotes"
			static let offset = "offset"
			static let asset = "asset"
		}
	}
	
}

// MARK: CloudKitModel

extension Image: VCKModel {
    
    public var cloudKitRecordID: CKRecord.ID {
        guard let zoneID = outline?.zoneID else { fatalError("Missing Outline in Image.") }
        return CKRecord.ID(recordName: id.description, zoneID: zoneID)
    }
    
    public func apply(_ record: CKRecord) {
        
    }
    
    public func apply(_ error: CKError) {
        
    }
    
    public func buildRecord() -> CKRecord {
        return CKRecord(recordType: CloudKitRecord.recordType, recordID: cloudKitRecordID)
    }
    
    public func clearSyncData() {
        
    }
    
    public func deleteTempFiles() {
        
    }

}

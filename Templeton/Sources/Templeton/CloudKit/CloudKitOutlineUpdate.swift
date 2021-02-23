//
//  CloudKitOutlineUpdate.swift
//  
//
//  Created by Maurice Parker on 2/20/21.
//

import Foundation
import CloudKit

class CloudKitOutlineUpdate {
	
	var documentID: EntityID
	var zoneID: CKRecordZone.ID
	var isDelete = false
	
	var saveOutlineRecord: CKRecord?
	var deleteRowRecordIDs = [EntityID]()
	var saveRowRecords = [CKRecord]()
	
	init(documentID: EntityID, zoneID: CKRecordZone.ID) {
		self.documentID = documentID
		self.zoneID = zoneID
	}
	
}

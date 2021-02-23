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
	var isDelete = false
	
	var saveOutlineRecord: CKRecord?
	var deleteRowRecordIDs = [EntityID]()
	var saveRowRecords = [CKRecord]()
	
	init(documentID: EntityID) {
		self.documentID = documentID
	}
	
}

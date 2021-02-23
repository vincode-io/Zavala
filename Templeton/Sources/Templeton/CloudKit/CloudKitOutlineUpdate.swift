//
//  CloudKitOutlineUpdate.swift
//  
//
//  Created by Maurice Parker on 2/20/21.
//

import Foundation
import CloudKit

class CloudKitOutlineUpdate {
	
	var recordID: CKRecord.ID
	var isDelete = false
	
	var saveOutlineRecord: CKRecord?
	var deleteRowRecordIDs = [CKRecord.ID]()
	var saveRowRecords = [CKRecord]()
	
	init(recordID: CKRecord.ID) {
		self.recordID = recordID
	}
	
}

//
//  CloudKitModel.swift
//  
//
//  Created by Maurice Parker on 3/18/23.
//

import Foundation
import CloudKit

public protocol CloudKitModel {
	
	var cloudKitRecordID: CKRecord.ID { get }
	var cloudKitMetaData: Data? { get set }
	
	func apply(_: CKRecord)
	func buildClientRecord() -> CKRecord
	func buildAncestorRecord() -> CKRecord
	func clearAncestorData()
	
}

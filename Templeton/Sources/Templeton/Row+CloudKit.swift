//
//  Row+CloudKit.swift
//  
//
//  Created by Maurice Parker on 3/15/23.
//

import Foundation
import CloudKit

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

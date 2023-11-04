//
//  Image+CloudKit.swift
//  
//
//  Created by Maurice Parker on 3/15/23.
//

import Foundation
import CloudKit

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

//extension Image {
//

//
//}

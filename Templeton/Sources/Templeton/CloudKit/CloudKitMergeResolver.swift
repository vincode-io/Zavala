//
//  CloudKitMergeResolver.swift
//  
//
//  Created by Maurice Parker on 11/1/22.
//

import Foundation
import CloudKit
import RSCore

struct CloudKitMergeResolver: CloudKitConflictResolver {
	
	func resolve(_: CloudKitResult) -> [Result<CKRecord, CKError>] {
		return []
	}
	
}

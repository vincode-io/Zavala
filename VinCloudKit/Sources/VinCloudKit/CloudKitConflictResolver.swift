//
//  CloudKitConflictResolver.swift
//  
//
//  Created by Maurice Parker on 11/1/22.
//

import Foundation
import CloudKit

/// This is a way for clients to specify how to resolve `serverRecordChanged` errors.
public protocol CloudKitConflictResolver {
	
	/// The models that may need to have a conflict resolved for
	var modelsToSave: [CloudKitModel]? { get set }
	
	/// This is the function resolves the conflict and returns the results
	func resolve(_: CloudKitResult) throws -> [CKRecord]
	
}

public extension CloudKitConflictResolver {
	
}

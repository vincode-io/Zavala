//
//  File.swift
//  
//
//  Created by Maurice Parker on 12/30/20.
//

import Foundation

public extension Array where Element == Row {
	
	func sortedByDisplayOrder() -> Array {
		return sorted(by: { $0.shadowTableIndex ?? -1 < $1.shadowTableIndex ?? -1 })
	}
	
	func sortedByReverseDisplayOrder() -> Array {
		return sorted(by: { $0.shadowTableIndex ?? -1 > $1.shadowTableIndex ?? -1 })
	}
	
}

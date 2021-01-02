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

	func sortedWithDecendentsFiltered() -> Array {
		let sortedRows = sortedByDisplayOrder()
		
		var filteredRows = [Row]()
		for row in sortedRows {
			var decendent = false
			for filteredRow in filteredRows {
				if row.isDecendent(filteredRow) {
					decendent = true
					break
				}
			}
			if !decendent {
				filteredRows.append(row)
			}
		}

		return filteredRows
	}
	
}

//
//  TransientDataVisitor.swift
//  
//
//  Created by Maurice Parker on 11/24/20.
//

import Foundation

class TransientDataVisitor {
	
	let isFiltered: Bool
	let isSearching: Bool
	var shadowTable = [Row]()
	var addingToShadowTable = true
	
	init(isFiltered: Bool, isSearching: Bool) {
		self.isFiltered = isFiltered
		self.isSearching = isSearching
	}
	
	func visitor(_ visited: Row) {

		var mutatingVisited = visited
		var addingToShadowTableSuspended = false
		
		// Add to the Shadow Table if we haven't hit a collapsed entry
		if addingToShadowTable {
			
			let shouldFilter = isFiltered && visited.isComplete
			
			if shouldFilter {
				mutatingVisited.shadowTableIndex = nil
			} else {
				mutatingVisited.shadowTableIndex = shadowTable.count
				shadowTable.append(visited)
			}
			
			if (!visited.isExpanded && !isSearching) || shouldFilter {
				addingToShadowTable = false
				addingToShadowTableSuspended = true
			}
			
		} else {
			
			mutatingVisited.shadowTableIndex = nil
			
		}
		
		// Set all the Headline's children's parent and visit them
		visited.rows.forEach { row in
			var mutatingRow = row
			mutatingRow.parent = visited
			mutatingRow.visit(visitor: visitor)
		}

		if addingToShadowTableSuspended {
			addingToShadowTable = true
		}
		
	}
	
}

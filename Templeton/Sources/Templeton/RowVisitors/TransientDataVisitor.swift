//
//  TransientDataVisitor.swift
//  
//
//  Created by Maurice Parker on 11/24/20.
//

import Foundation

class TransientDataVisitor {
	
	let isFiltered: Bool
	let isSearching: Outline.SearchState
	var shadowTable = [Row]()
	var addingToShadowTable = true
	
	init(isFiltered: Bool, isSearching: Outline.SearchState) {
		self.isFiltered = isFiltered
		self.isSearching = isSearching
	}
	
	func visitor(_ visited: Row) {

		var addingToShadowTableSuspended = false
		
		// Add to the Shadow Table if we haven't hit a collapsed entry
		if addingToShadowTable {
			
			let shouldFilter = (isFiltered && visited.isComplete) || (isSearching == .searching && !visited.isPartOfSearchResult)
			
			if shouldFilter {
				visited.shadowTableIndex = nil
			} else {
				visited.shadowTableIndex = shadowTable.count
				shadowTable.append(visited)
			}
			
			if (!visited.isExpanded && isSearching == .notSearching) || shouldFilter {
				addingToShadowTable = false
				addingToShadowTableSuspended = true
			}
			
		} else {
			
			visited.shadowTableIndex = nil
			
		}
		
		// Set all the Headline's children's parent and visit them
		visited.rows.forEach { row in
			row.parent = visited
			row.visit(visitor: visitor)
		}

		if addingToShadowTableSuspended {
			addingToShadowTable = true
		}
		
	}
	
}

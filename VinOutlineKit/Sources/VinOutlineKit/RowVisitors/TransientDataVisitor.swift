//
//  TransientDataVisitor.swift
//  
//
//  Created by Maurice Parker on 11/24/20.
//

import Foundation

@MainActor
final class TransientDataVisitor {
	
	let isCompletedFilterOn: Bool
	let isSearching: Outline.SearchState
	let reloadMovedRows: Bool
	
	var shadowTable = [Row]()
	var reloads = Set<Int>()
	
	private var addingToShadowTable = true
	
	init(isCompletedFilterOn: Bool, isSearching: Outline.SearchState, reloadMovedRows: Bool) {
		self.isCompletedFilterOn = isCompletedFilterOn
		self.isSearching = isSearching
		self.reloadMovedRows = reloadMovedRows
	}
	
	func visitor(_ visited: Row) {

		var addingToShadowTableSuspended = false
		
		// Add to the Shadow Table if we haven't hit a collapsed entry
		if addingToShadowTable {
			
			let shouldFilter = (isCompletedFilterOn && visited.isComplete ?? false) || (isSearching == .searching && !visited.isPartOfSearchResult)
			
			if shouldFilter {
				visited.shadowTableIndex = nil
			} else {
				if reloadMovedRows && visited.shadowTableIndex != shadowTable.count {
					reloads.insert(shadowTable.count)
				}
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

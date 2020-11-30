//
//  TransientDataVisitor.swift
//  
//
//  Created by Maurice Parker on 11/24/20.
//

import Foundation

class TransientDataVisitor {
	
	let isFiltered: Bool
	var shadowTable = [Headline]()
	var addingToShadowTable = true
	var ancestorIsComplete = false
	
	init(isFiltered: Bool) {
		self.isFiltered = isFiltered
	}
	
	func visitor(_ visited: Headline) {

		var addingToShadowTableSuspended = false
		
		// Add to the Shadow Table if we haven't hit a collapsed entry
		if addingToShadowTable {
			
			let shouldFilter = isFiltered && visited.isComplete ?? false
			
			if shouldFilter {
				visited.shadowTableIndex = nil
			} else {
				visited.shadowTableIndex = shadowTable.count
				shadowTable.append(visited)
			}
			
			if !(visited.isExpanded ?? true) || shouldFilter {
				addingToShadowTable = false
				addingToShadowTableSuspended = true
			}
			
		} else {
			
			visited.shadowTableIndex = nil
			
		}
		
		visited.isAncestorComplete = ancestorIsComplete
		
		var markingChildrenAsAncestorCompleted = false
		
		if visited.isComplete ?? false {
			ancestorIsComplete = true
			markingChildrenAsAncestorCompleted = true
		}
		
		// Set all the Headline's children's parent and visit them
		visited.headlines?.forEach {
			$0.parent = visited
			$0.visit(visitor: visitor)
		}

		if addingToShadowTableSuspended {
			addingToShadowTable = true
		}
		
		if markingChildrenAsAncestorCompleted {
			ancestorIsComplete = false
		}
		
	}
	
}

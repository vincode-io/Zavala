//
//  TransientDataVisitor.swift
//  
//
//  Created by Maurice Parker on 11/24/20.
//

import Foundation

class TransientDataVisitor {
	
	var shadowTable = [Headline]()
	var addingToShadowTable = true
	var level = 0

	func visitor(_ visited: Headline) {

		var addingToShadowTableSuspended = false
		
		// Add to the Shadow Table if we haven't hit a collapsed entry
		if addingToShadowTable {
			visited.shadowTableIndex = shadowTable.count
			shadowTable.append(visited)
			if !(visited.isExpanded ?? true) {
				addingToShadowTable = false
				addingToShadowTableSuspended = true
			}
		} else {
			visited.shadowTableIndex = nil
		}
		
		// Set the indent level for the Headline
		visited.indentLevel = level
		level = level + 1

		// Set all the Headline's children's parent and visit them
		visited.headlines?.forEach {
			$0.parent = visited
			$0.visit(visitor: visitor)
		}

		level = level - 1

		if addingToShadowTableSuspended {
			addingToShadowTable = true
		}
		
	}
	
}

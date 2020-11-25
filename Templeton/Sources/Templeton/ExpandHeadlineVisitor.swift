//
//  ExpandHeadlineVisitor.swift
//  
//
//  Created by Maurice Parker on 11/25/20.
//

import Foundation

class ExpandHeadlineVisitor {

	var shadowTableInserts = [Headline]()

	func visitor(_ visited: Headline) {
		shadowTableInserts.append(visited)

		if visited.isExpanded ?? true {
			visited.headlines?.forEach {
				$0.visit(visitor: visitor)
			}
		}
	}
	
}

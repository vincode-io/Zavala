//
//  CollapseHeadlineVisitor.swift
//  
//
//  Created by Maurice Parker on 11/25/20.
//

import Foundation

class CollapseHeadlineVisitor {

	var shadowTableIndexes = [Int]()

	func visitor(_ visited: Headline) {
		if let shadowTableIndex = visited.shadowTableIndex {
			shadowTableIndexes.append(shadowTableIndex)
		}

		if visited.isExpanded ?? true {
			visited.headlines?.forEach {
				$0.visit(visitor: visitor)
			}
		}
	}
	
}

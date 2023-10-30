//
//  IntentRow+.swift
//  Zavala
//
//  Created by Maurice Parker on 10/21/21.
//

import Foundation
import VinOutlineKit

extension IntentRow {
	
	convenience init(_ row: Row) {
		let topicMarkdown = row.topicMarkdown(representation: .markdown)
		
		self.init(identifier: row.entityID.description, display: topicMarkdown ?? "")
		entityID = IntentEntityID(row.entityID)
		
		topic = topicMarkdown
		note = row.noteMarkdown(representation: .markdown)
		
		complete = NSNumber(booleanLiteral: row.isComplete)
		expanded = NSNumber(booleanLiteral: row.isExpanded)
		level = NSNumber(integerLiteral: row.level)
	}
	
}

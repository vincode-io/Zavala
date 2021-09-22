//
//  MarkdownDocVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import Foundation

class MarkdownDocVisitor {
	
	var indentLevel = 0
	var markdown = String()
	
	func visitor(_ visited: Row) {
		guard let textRow = visited.textRow else { return }

		if let topicMarkdown = textRow.topicMarkdown, !topicMarkdown.isEmpty {
			markdown.append("\n\n")
			markdown.append(String(repeating: "#", count: indentLevel + 2))
			markdown.append(" \(topicMarkdown)")
		}
		
		if let noteMarkdown = textRow.noteMarkdown {
			markdown.append("\n\n\(noteMarkdown)")
		}
		
		indentLevel = indentLevel + 1
		textRow.rows.forEach {
			$0.visit(visitor: self.visitor)
		}
		indentLevel = indentLevel - 1
	}
	
}

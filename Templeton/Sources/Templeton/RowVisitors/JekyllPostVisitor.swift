//
//  JekyllPostVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import Foundation

class JekyllPostVisitor {
	
	var indentLevel = 0
	var markdown = String()
	
	func visitor(_ visited: Row) {
		guard let textRow = visited.textRow else { return }

		markdown.append(String(repeating: "#", count: indentLevel + 2))
		markdown.append(" \(textRow.topicMarkdown ?? "")")
		
		if let notePlainText = textRow.noteMarkdown {
			markdown.append("\n\n\(notePlainText)")
		}
		
		indentLevel = indentLevel + 1
		textRow.rows.forEach {
			markdown.append("\n\n")
			$0.visit(visitor: self.visitor)
		}
		indentLevel = indentLevel - 1
	}
	
}

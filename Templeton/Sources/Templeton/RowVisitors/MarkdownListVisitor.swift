//
//  MarkdownListVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import Foundation

class MarkdownListVisitor {
	
	var indentLevel = 0
	var markdown = String()
	
	func visitor(_ visited: Row) {
		guard let textRow = visited.textRow else { return }

		markdown.append(String(repeating: "\t", count: indentLevel))
		
		if textRow.isComplete {
			markdown.append("* ~~\(textRow.topicMarkdown ?? "")~~")
		} else {
			markdown.append("* \(textRow.topicMarkdown ?? "")")
		}
		
		if let noteMarkdown = textRow.noteMarkdown, !noteMarkdown.isEmpty {
			markdown.append("\n\n")
			let paragraphs = noteMarkdown.components(separatedBy: "\n\n")
			for paragraph in paragraphs {
				markdown.append(String(repeating: "\t", count: indentLevel))
				markdown.append("  \(paragraph)\n\n")
			}
		}
		
		indentLevel = indentLevel + 1
		textRow.rows.forEach {
			markdown.append("\n")
			$0.visit(visitor: self.visitor)
		}
		indentLevel = indentLevel - 1
	}
	
}

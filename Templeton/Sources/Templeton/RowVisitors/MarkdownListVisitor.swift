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
		markdown.append(String(repeating: "\t", count: indentLevel))
		
		if visited.isComplete {
			markdown.append("* ~~\(visited.topicMarkdown ?? "")~~")
		} else {
			markdown.append("* \(visited.topicMarkdown ?? "")")
		}
		
		if let noteMarkdown = visited.noteMarkdown, !noteMarkdown.isEmpty {
			markdown.append("\n\n")
			let paragraphs = noteMarkdown.components(separatedBy: "\n\n")
			for paragraph in paragraphs {
				markdown.append(String(repeating: "\t", count: indentLevel))
				markdown.append("  \(paragraph)\n\n")
			}
		}
		
		indentLevel = indentLevel + 1
		visited.rows.forEach {
			markdown.append("\n")
			$0.visit(visitor: self.visitor)
		}
		indentLevel = indentLevel - 1
	}
	
}

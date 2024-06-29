//
//  MarkdownListVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import Foundation

@MainActor
final class MarkdownListVisitor {
	
	let useAltLinks: Bool
	var indentLevel = 0
	var markdown = String()
	
	init(useAltLinks: Bool) {
		self.useAltLinks = useAltLinks
	}
	
	func visitor(_ visited: Row) {
		markdown.append(String(repeating: "\t", count: indentLevel))
		
		if visited.isComplete ?? false {
			markdown.append("* ~~\(visited.topicMarkdown(representation: .markdown, useAltLinks: useAltLinks) ?? "")~~")
		} else {
			markdown.append("* \(visited.topicMarkdown(representation: .markdown, useAltLinks: useAltLinks) ?? "")")
		}
		
		if let noteMarkdown = visited.noteMarkdown(representation: .markdown, useAltLinks: useAltLinks), !noteMarkdown.isEmpty {
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

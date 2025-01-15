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
	let numberingStyle: Outline.NumberingStyle
	
	var indentLevel = 0
	var markdown = String()
	
	init(useAltLinks: Bool, numberingStyle: Outline.NumberingStyle) {
		self.useAltLinks = useAltLinks
		self.numberingStyle = numberingStyle
	}
	
	func visitor(_ visited: Row) {
		markdown.append(String(repeating: "\t", count: indentLevel))
		
		if numberingStyle == .none {
			if visited.isComplete ?? false {
				markdown.append("* ~~\(visited.topicMarkdown(type: .markdown, useAltLinks: useAltLinks) ?? "")~~")
			} else {
				markdown.append("* \(visited.topicMarkdown(type: .markdown, useAltLinks: useAltLinks) ?? "")")
			}
		} else {
			if visited.isComplete ?? false {
				markdown.append("\(visited.simpleNumbering) ~~\(visited.topicMarkdown(type: .markdown, useAltLinks: useAltLinks) ?? "")~~")
			} else {
				markdown.append("\(visited.simpleNumbering) \(visited.topicMarkdown(type: .markdown, useAltLinks: useAltLinks) ?? "")")
			}
		}
		
		if let noteMarkdown = visited.noteMarkdown(type: .markdown, useAltLinks: useAltLinks), !noteMarkdown.isEmpty {
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

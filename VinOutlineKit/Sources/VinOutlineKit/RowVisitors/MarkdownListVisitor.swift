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
	let useSidecar: Bool
	let numberingStyle: Outline.NumberingStyle
	
	var indentLevel = 0
	var markdown = String()
	
	init(useAltLinks: Bool, useSidecar: Bool, numberingStyle: Outline.NumberingStyle) {
		self.useAltLinks = useAltLinks
		self.useSidecar = useSidecar
		self.numberingStyle = numberingStyle
	}
	
	func visitor(_ visited: Row) {
		markdown.append(String(repeating: "\t", count: indentLevel))
		
		if numberingStyle == .none {
			if visited.isComplete ?? false {
				markdown.append("* ~~\(visited.topicMarkdown(type: .markdown, useAltLinks: useAltLinks, useSidecar: useSidecar) ?? "")~~")
			} else {
				markdown.append("* \(visited.topicMarkdown(type: .markdown, useAltLinks: useAltLinks, useSidecar: useSidecar) ?? "")")
			}
		} else {
			if visited.isComplete ?? false {
				markdown.append("\(visited.simpleNumbering) ~~\(visited.topicMarkdown(type: .markdown, useAltLinks: useAltLinks, useSidecar: useSidecar) ?? "")~~")
			} else {
				markdown.append("\(visited.simpleNumbering) \(visited.topicMarkdown(type: .markdown, useAltLinks: useAltLinks, useSidecar: useSidecar) ?? "")")
			}
		}
		
		if let noteMarkdown = visited.noteMarkdown(type: .markdown, useAltLinks: useAltLinks, useSidecar: useSidecar), !noteMarkdown.isEmpty {
			markdown.append("\n\n")
			let paragraphs = noteMarkdown.components(separatedBy: "\n\n")
			for paragraph in paragraphs {
				let lines = paragraph.components(separatedBy: "\n")
				for line in lines {
					markdown.append(String(repeating: "\t", count: indentLevel))
					markdown.append("  \(line)\n")
				}
				markdown.append("\n")
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

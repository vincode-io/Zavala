//
//  MarkdownDocVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import Foundation
import VinUtility

@MainActor
final class MarkdownDocVisitor {
	
	let useAltLinks: Bool
	let useSidecar: Bool
	var indentLevel = 0
	var markdown = String()
	
	var previousRowWasParagraph = false
	
	init(useAltLinks: Bool, useSidecar: Bool) {
		self.useAltLinks = useAltLinks
		self.useSidecar = useSidecar
	}
	
	func visitor(_ visited: Row) {
		
		func visitChildren() {
			indentLevel = indentLevel + 1
			visited.rows.forEach {
				$0.visit(visitor: self.visitor)
			}
			indentLevel = indentLevel - 1
		}

		if let topicMarkdown = visited.topicMarkdown(type: .markdown, useAltLinks: useAltLinks, useSidecar: useSidecar), !topicMarkdown.isEmpty {
			if let noteMarkdown = visited.noteMarkdown(type: .markdown, useAltLinks: useAltLinks, useSidecar: useSidecar), !noteMarkdown.isEmpty {
				markdown.append("\n\n")
				markdown.append(String(repeating: "#", count: indentLevel + 2))
				markdown.append(" \(topicMarkdown)")
				markdown.append("\n\n\(noteMarkdown)")
				previousRowWasParagraph = true
				
				visitChildren()
			} else {
				if previousRowWasParagraph {
					markdown.append("\n")
				}

				let listVisitor = MarkdownListVisitor(useAltLinks: useAltLinks, useSidecar: useSidecar, numberingStyle: .none)
				markdown.append("\n")
				visited.visit(visitor: listVisitor.visitor)
				markdown.append(listVisitor.markdown)
				
				previousRowWasParagraph = false
			}
		} else {
			if let noteMarkdown = visited.noteMarkdown(type: .markdown, useAltLinks: useAltLinks, useSidecar: useSidecar), !noteMarkdown.isEmpty {
				markdown.append("\n\n\(noteMarkdown)")
				previousRowWasParagraph = true
			} else {
				previousRowWasParagraph = false
			}
			
			visitChildren()
		}
		
	}
	
}

//
//  MarkdownDocVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import Foundation
import UniformTypeIdentifiers
import VinUtility

@MainActor
final class MarkdownDocVisitor {

	let useAltLinks: Bool
	let useSidecar: Bool
	let linkType: UTType

	/// Maps the ID of each Row that can be linked to onto the link that the export uses for it.
	let headingLinks: [String: String]

	var indentLevel = 0
	var markdown = String()

	var previousRowWasParagraph = false

	/// The Rows that were exported as headings, in the order that they appear in the document.
	private(set) var headingRows = [Row]()

	init(useAltLinks: Bool, useSidecar: Bool, linkType: UTType = .md, headingLinks: [String: String] = [:]) {
		self.useAltLinks = useAltLinks
		self.useSidecar = useSidecar
		self.linkType = linkType
		self.headingLinks = headingLinks
	}
	
	func visitor(_ visited: Row) {
		
		func visitChildren() {
			indentLevel = indentLevel + 1
			visited.rows.forEach {
				$0.visit(visitor: self.visitor)
			}
			indentLevel = indentLevel - 1
		}

		if let topicMarkdown = visited.topicMarkdown(type: linkType, format: true, useAltLinks: useAltLinks, useSidecar: useSidecar, headingLinks: headingLinks), !topicMarkdown.isEmpty {
			if let noteMarkdown = visited.noteMarkdown(type: linkType, format: true, useAltLinks: useAltLinks, useSidecar: useSidecar, headingLinks: headingLinks) {
				markdown.append("\n\n")
				markdown.append(String(repeating: "#", count: indentLevel + 2))
				markdown.append(" \(topicMarkdown)")
				if !noteMarkdown.isEmpty {
					markdown.append("\n\n\(noteMarkdown)")
				}
				previousRowWasParagraph = true
				headingRows.append(visited)

				visitChildren()
			} else {
				if previousRowWasParagraph {
					markdown.append("\n")
				}

				let listVisitor = MarkdownListVisitor(format: true, useAltLinks: useAltLinks, useSidecar: useSidecar, numberingStyle: .none, linkType: linkType, headingLinks: headingLinks)
				markdown.append("\n")
				visited.visit(visitor: listVisitor.visitor)
				markdown.append(listVisitor.markdown)
				
				previousRowWasParagraph = false
			}
		} else {
			if let noteMarkdown = visited.noteMarkdown(type: linkType, format: true, useAltLinks: useAltLinks, useSidecar: useSidecar, headingLinks: headingLinks) {
				if !noteMarkdown.isEmpty {
					markdown.append("\n\n\(noteMarkdown)")
				}
				previousRowWasParagraph = true
			} else {
				previousRowWasParagraph = false
			}
			
			visitChildren()
		}
		
	}
	
}

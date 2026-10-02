//
//  MarkdownListVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import Foundation
import UniformTypeIdentifiers

@MainActor
final class MarkdownListVisitor {

	let format: Bool
	let useAltLinks: Bool
	let useSidecar: Bool
	let numberingStyle: Outline.NumberingStyle
	let linkType: UTType

	/// Maps the ID of each Row that can be linked to onto the link that the export uses for it.
	let headingLinks: [String: String]

	var indentLevel = 0
	var markdown = String()

	init(format: Bool, useAltLinks: Bool, useSidecar: Bool, numberingStyle: Outline.NumberingStyle, linkType: UTType = .md, headingLinks: [String: String] = [:]) {
		self.format = format
		self.useAltLinks = useAltLinks
		self.useSidecar = useSidecar
		self.numberingStyle = numberingStyle
		self.linkType = linkType
		self.headingLinks = headingLinks
	}
	
	func visitor(_ visited: Row) {
		let indent = String(repeating: "\t", count: indentLevel)
		let marker = numberingStyle == .none ? "*" : visited.simpleNumbering
		let topicMarkdown = visited.topicMarkdown(type: linkType, format: format, useAltLinks: useAltLinks, useSidecar: useSidecar, headingLinks: headingLinks) ?? ""

		// Strikethrough can't span paragraphs, so a completed topic with more than one has each one struck through.
		var topicParagraphs = topicMarkdown.components(separatedBy: "\n\n")
		if visited.isComplete ?? false {
			topicParagraphs = topicParagraphs.map { $0.isEmpty ? $0 : "~~\($0)~~" }
		}

		// Lines after the first are indented under the list item, the same as notes, so that they stay part of it
		// instead of starting a new paragraph outside of the list.
		let topicLines = topicParagraphs.joined(separator: "\n\n").components(separatedBy: "\n")
		markdown.append("\(indent)\(marker) \(topicLines[0])")
		for line in topicLines.dropFirst() {
			markdown.append(line.isEmpty ? "\n" : "\n\(indent)  \(line)")
		}
		
		if let noteMarkdown = visited.noteMarkdown(type: linkType, format: format, useAltLinks: useAltLinks, useSidecar: useSidecar, headingLinks: headingLinks), !noteMarkdown.isEmpty {
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

//
//  OPMLVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import Foundation
import VinUtility

@MainActor
final class OPMLVisitor {
	
	let useAltLinks: Bool
	var indentLevel = 0
	var opml = String()
	
	init(useAltLinks: Bool) {
		self.useAltLinks = useAltLinks
	}
	
	func visitor(_ visited: Row) {
		let indent = String(repeating: " ", count: (indentLevel + 1) * 2)
		let escapedText = visited.topicMarkdown(representation: .opml, useAltLinks: useAltLinks)?.escapingXMLCharacters ?? ""
		
		opml.append(indent + "<outline text=\"\(escapedText)\"")
		if let escapedNote = visited.noteMarkdown(representation: .opml, useAltLinks: useAltLinks)?.escapingXMLCharacters {
			opml.append(" _note=\"\(escapedNote)\"")
		}

		if visited.isComplete ?? false {
			opml.append(" _status=\"checked\"")
		}
		
		if visited.rowCount == 0 {
			opml.append("/>\n")
		} else {
			opml.append(">\n")
			indentLevel = indentLevel + 1
			visited.rows.forEach { $0.visit(visitor: self.visitor) }
			indentLevel = indentLevel - 1
			opml.append(indent + "</outline>\n")
		}
	}
	
}

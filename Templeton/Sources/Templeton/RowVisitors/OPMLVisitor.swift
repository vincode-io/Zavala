//
//  OPMLVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import Foundation

class OPMLVisitor {
	
	var indentLevel = 0
	var opml = String()
	
	func visitor(_ visited: Row) {
		guard let textRow = visited.textRow else { return }
		
		let indent = String(repeating: " ", count: (indentLevel + 1) * 2)
		let escapedText = textRow.topicMarkdown?.escapingSpecialXMLCharacters ?? ""
		
		opml.append(indent + "<outline text=\"\(escapedText)\"")
		if let escapedNote = textRow.noteMarkdown?.escapingSpecialXMLCharacters {
			opml.append(" _note=\"\(escapedNote)\"")
		}

		if textRow.isComplete {
			opml.append(" _status=\"checked\"")
		}
		
		if textRow.rowCount == 0 {
			opml.append("/>\n")
		} else {
			opml.append(">\n")
			indentLevel = indentLevel + 1
			textRow.rows.forEach { $0.visit(visitor: self.visitor) }
			indentLevel = indentLevel - 1
			opml.append(indent + "</outline>\n")
		}
	}
	
}

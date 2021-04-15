//
//  StringVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import Foundation

class StringVisitor {

	var indentLevel = 0
	var string = String()
	
	func visitor(_ visited: Row) {
		guard let textRow = visited.textRow else { return }

		string.append(String(repeating: "\t", count: indentLevel))
		string.append("\(textRow.topic?.string ?? "")")
		
		if let notePlainText = textRow.note?.string {
			string.append("\n\(notePlainText)")
		}
		
		string.append("\n")
		indentLevel = indentLevel + 1
		textRow.rows.forEach { $0.visit(visitor: self.visitor) }
		indentLevel = indentLevel - 1
	}
	
}

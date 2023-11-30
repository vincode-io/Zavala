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
		string.append(String(repeating: "\t", count: indentLevel))
		string.append("\(visited.topic?.string ?? "")")
		
		if let notePlainText = visited.note?.string {
			string.append("\n\(notePlainText)")
		}
		
		indentLevel = indentLevel + 1
		visited.rows.forEach {
			string.append("\n")
			$0.visit(visitor: self.visitor)
		}
		indentLevel = indentLevel - 1
	}
	
}

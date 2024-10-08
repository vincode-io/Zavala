//
//  Created by Maurice Parker on 1/3/24.
//

import Foundation

@MainActor
final class WordCountVisitor {

	var count = 0
	
	func visitor(_ visited: Row) {
		if let topic = visited.topic?.string {
			count = count + topic.split(separator: " ", omittingEmptySubsequences: true).count
		}
		
		if let note = visited.note?.string {
			count = count + note.split(separator: " ", omittingEmptySubsequences: true).count
		}

		visited.rows.forEach {
			$0.visit(visitor: self.visitor)
		}
	}
	
}

//
//  Created by Maurice Parker on 6/12/24.
//

import Foundation
import Testing
import Markdown
@testable import VinOutlineKit

final class SimpleRowWalkerTests: VOKTestCase {
	
	@Test func singleTextRow() throws {
		let document = Document(parsing: "This is just a sentence.")
		var walker = SimpleRowWalker()
		walker.visit(document)
		
		#expect(walker.rows.count == 1)
		#expect(walker.rows[0].topicMarkdown(type: .markdown) == "This is just a sentence.")
	}
	
	@Test func multipleTextRow() throws {
		let document = Document(parsing: "This is just a sentence.\nSo is this.\nThe third sentence.")
		var walker = SimpleRowWalker()
		walker.visit(document)
		
		#expect(walker.rows.count == 3)
	}
	
	@Test func singleBulletRow() throws {
		let document = Document(parsing: "*\tThis is *just* a sentence.")
		var walker = SimpleRowWalker()
		walker.visit(document)
		
		#expect(walker.rows.count == 1)
		#expect(walker.rows[0].topicMarkdown(type: .markdown) == "This is _just_ a sentence.")
	}
	
	@Test func unorderedList() throws {
		let outline = """
* Row 1
	* Row 1.1
	* Row 1.2
* Row 2
	* Row 2.1
	* Row 2.2
	* Row 2.3
* Row 3
	* Row 3.1
		* Row 3.1.1
		* Row 3.1.2
"""
		let document = Document(parsing: outline)
		var walker = SimpleRowWalker()
		walker.visit(document)

		#expect(walker.rows.count == 3)
		#expect(walker.rows[0].rows.count == 2)
		#expect(walker.rows[1].rows.count == 3)
		#expect(walker.rows[2].rows.count == 1)
		#expect(walker.rows[2].rows[0].rows.count == 2)
	}
	
}

//
//  Created by Maurice Parker on 6/12/24.
//

import XCTest
import Markdown
@testable import VinOutlineKit

final class SimpleRowWalkerTests: VOKTestCase {
	
	func testSingleTextRow() throws {
		let document = Document(parsing: "This is just a sentence.")
		var walker = SimpleRowWalker(outline: try loadOutline())
		walker.visit(document)
		
		XCTAssertEqual(walker.rows.count, 1)
		XCTAssertEqual(walker.rows[0].topicMarkdown(representation: .markdown), "This is just a sentence.")
	}
	
	func testMultipleTextRow() throws {
		let document = Document(parsing: "This is just a sentence.\nSo is this.\nThe third sentence.")
		var walker = SimpleRowWalker(outline: try loadOutline())
		walker.visit(document)
		
		XCTAssertEqual(walker.rows.count, 3)
	}
	
	func testSingleBulletRow() throws {
		let document = Document(parsing: "*\tThis is *just* a sentence.")
		var walker = SimpleRowWalker(outline: try loadOutline())
		walker.visit(document)
		
		XCTAssertEqual(walker.rows.count, 1)
		XCTAssertEqual(walker.rows[0].topicMarkdown(representation: .markdown), "This is _just_ a sentence.")
	}
	
	func testUnorderedList() throws {
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
		print(document.debugDescription())
		var walker = SimpleRowWalker(outline: try loadOutline())
		walker.visit(document)
		
		XCTAssertEqual(walker.rows.count, 3)
		XCTAssertEqual(walker.rows[0].rows.count, 2)
		XCTAssertEqual(walker.rows[1].rows.count, 3)
		XCTAssertEqual(walker.rows[2].rows.count, 1)
		XCTAssertEqual(walker.rows[2].rows[0].rows.count, 2)
	}
	
}

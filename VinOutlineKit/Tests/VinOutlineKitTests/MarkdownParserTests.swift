//
//  Created by Maurice Parker on 6/12/24.
//

import Foundation
import Testing
import Markdown
@testable import VinOutlineKit

final class MarkdownParserTests: VOKTestCase {
	
	@Test func singleTextRow() throws {
		let document = Document(parsing: "This is just a sentence.")
		var parser = MarkdownParser()
		parser.visit(document)
		
		#expect(parser.outline.rows.count == 1)
		#expect(parser.outline.rows[0].topicMarkdown(type: .markdown) == "This is just a sentence.")
	}
	
	@Test func multipleTextRow() throws {
		let document = Document(parsing: "This is just a sentence.\nSo is this.\nThe third sentence.")
		var parser = MarkdownParser()
		parser.visit(document)
		
		#expect(parser.outline.rows.count == 3)
	}
	
	@Test func singleBulletRow() throws {
		let document = Document(parsing: "*\tThis is *just* a sentence.")
		var parser = MarkdownParser()
		parser.visit(document)
		
		#expect(parser.outline.rows.count == 1)
		#expect(parser.outline.rows[0].topicMarkdown(type: .markdown) == "This is _just_ a sentence.")
	}
	
	@Test func orderedList() throws {
		let markdown = """
1. Row 1
	1. Row 1.1
	2. Row 1.2
2. Row 2
	1. Row 2.1
	2. Row 2.2
	3. Row 2.3
3. Row 3
	1. Row 3.1
		1. Row 3.1.1
		2. Row 3.1.2
"""
		let document = Document(parsing: markdown)
		var parser = MarkdownParser()
		parser.visit(document)

		#expect(parser.outline.rows.count == 3)
		#expect(parser.outline.rows[0].rows.count == 2)
		#expect(parser.outline.rows[1].rows.count == 3)
		#expect(parser.outline.rows[2].rows.count == 1)
		#expect(parser.outline.rows[2].rows[0].rows.count == 2)
	}
	
	@Test func unorderedList() throws {
		let markdown = """
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
		let document = Document(parsing: markdown)
		var parser = MarkdownParser()
		parser.visit(document)

		#expect(parser.outline.rows.count == 3)
		#expect(parser.outline.rows[0].rows.count == 2)
		#expect(parser.outline.rows[1].rows.count == 3)
		#expect(parser.outline.rows[2].rows.count == 1)
		#expect(parser.outline.rows[2].rows[0].rows.count == 2)
	}

	@Test func fullOutline() throws {
		let markdown = loadMarkdown("MarkdownOutline")
		let document = Document(parsing: markdown)
		var parser = MarkdownParser()
		parser.visit(document)

		#expect(parser.outline.title == "Qualities of a Great Car")
		#expect(parser.outline.rows.count == 3)

		#expect(parser.outline.rows[0].topic?.string == "Section 1")
		#expect(parser.outline.rows[0].rows.count == 3)
		#expect(parser.outline.rows[0].rows[0].rows.count == 4)

		#expect(parser.outline.rows[1].topic?.string == "Section 2")

		#expect(parser.outline.rows[2].topic?.string == "Section 3")
	}
}

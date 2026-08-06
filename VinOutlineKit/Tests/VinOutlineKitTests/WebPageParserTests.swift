//
//  WebPageParserTests.swift
//  VinOutlineKitTests
//
//  Created by Maurice Parker on 8/5/26.
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit

final class WebPageParserTests: VOKTestCase {

	@Test func headingHierarchyAndNotes() throws {
		let accountManager = buildAccountManager()

		let html = """
		<h1>Top</h1>
		<p>Intro paragraph.</p>
		<h2>Sub</h2>
		<p>Sub paragraph.</p>
		"""

		let parser = ImportWebPageParser(account: accountManager.localAccount!, baseURL: nil, sourceImages: [:])
		parser.parse(contentHTML: html)

		#expect(parser.outline.rows.count == 1)
		#expect(parser.outline.rows[0].topic?.string == "Top")
		#expect(parser.outline.rows[0].note?.string == "Intro paragraph.")
		#expect(parser.outline.rows[0].rows.count == 1)
		#expect(parser.outline.rows[0].rows[0].topic?.string == "Sub")
		#expect(parser.outline.rows[0].rows[0].note?.string == "Sub paragraph.")
	}

	@Test func nestedLists() throws {
		let accountManager = buildAccountManager()

		let html = """
		<ul>
			<li>Row 1
				<ul>
					<li>Row 1.1</li>
					<li>Row 1.2</li>
				</ul>
			</li>
			<li>Row 2</li>
		</ul>
		"""

		let parser = ImportWebPageParser(account: accountManager.localAccount!, baseURL: nil, sourceImages: [:])
		parser.parse(contentHTML: html)

		#expect(parser.outline.rows.count == 2)
		#expect(parser.outline.rows[0].topic?.string == "Row 1")
		#expect(parser.outline.rows[0].rows.count == 2)
		#expect(parser.outline.rows[0].rows[0].topic?.string == "Row 1.1")
		#expect(parser.outline.rows[0].rows[1].topic?.string == "Row 1.2")
		#expect(parser.outline.rows[1].topic?.string == "Row 2")
		#expect(parser.outline.rows[1].rows.count == 0)
	}

	@Test func leadingContentBecomesEmptyTopicNote() throws {
		let accountManager = buildAccountManager()

		let html = """
		<p>First para.</p>
		<p>Second para.</p>
		<h2>Heading</h2>
		<p>Under heading.</p>
		"""

		let parser = ImportWebPageParser(account: accountManager.localAccount!, baseURL: nil, sourceImages: [:])
		parser.parse(contentHTML: html)

		#expect(parser.outline.rows.count == 2)

		#expect(parser.outline.rows[0].topic == nil)
		let leadingNote = try #require(parser.outline.rows[0].note)
		#expect(leadingNote.string == "First para.\n\nSecond para.")

		#expect(parser.outline.rows[1].topic?.string == "Heading")
		#expect(parser.outline.rows[1].note?.string == "Under heading.")
	}

	@Test func inlineFormattingIsPreserved() throws {
		let accountManager = buildAccountManager()

		let html = """
		<p>See <a href="https://example.com/x">the docs</a> for <strong>bold</strong>, \
		<em>italic</em>, <code>code()</code> and <mark>highlight</mark>.</p>
		"""

		let parser = ImportWebPageParser(account: accountManager.localAccount!, baseURL: nil, sourceImages: [:])
		parser.parse(contentHTML: html)

		#expect(parser.outline.rows.count == 1)
		let note = try #require(parser.outline.rows[0].note)

		// Exact string equality proves the markdown markers (**, *, `, ==, []()) were all consumed.
		#expect(note.string == "See the docs for bold, italic, code() and highlight.")

		// The link attribute survives on the anchor text.
		var foundLink: URL?
		note.enumerateAttribute(.link, in: NSRange(location: 0, length: note.length)) { value, _, _ in
			if let url = value as? URL {
				foundLink = url
			}
		}
		#expect(foundLink?.absoluteString == "https://example.com/x")

		// The highlight attribute survives on the marked text.
		var foundHighlight = false
		note.enumerateAttribute(.textHighlightStyle, in: NSRange(location: 0, length: note.length)) { value, _, _ in
			if value != nil {
				foundHighlight = true
			}
		}
		#expect(foundHighlight)
	}

	@Test func imagesAreEmbedded() throws {
		let accountManager = buildAccountManager()

		let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMEAYEXwj8AAAAASUVORK5CYII=")!
		let html = """
		<h2>Gallery</h2>
		<p><img src="https://example.com/pixel.png"></p>
		"""

		let parser = ImportWebPageParser(account: accountManager.localAccount!,
										 baseURL: URL(string: "https://example.com"),
										 sourceImages: ["https://example.com/pixel.png": pngData])
		parser.parse(contentHTML: html)

		#expect(parser.outline.rows.count == 1)
		let row = parser.outline.rows[0]
		#expect(row.topic?.string == "Gallery")
		// The image was embedded into the row's note (there is exactly one image on the outline).
		#expect(row.images?.count == 1)
	}

}

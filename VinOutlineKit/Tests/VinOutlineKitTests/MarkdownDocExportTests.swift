//
//  Created by Maurice Parker on 9/24/26.
//

import Foundation
import Testing
@testable import VinOutlineKit

final class MarkdownDocExportTests: VOKTestCase {

	@Test("Markdown Doc export converts a Row Link to a heading Row into a heading link")
	func rowLinkToHeadingRow() async throws {
		let accountManager = buildAccountManager()
		let outline = try buildOutline(accountManager: accountManager)

		let headingRow = Row(outline: outline, topicMarkdown: "My Heading", noteMarkdown: "Heading note")
		let linkingRow = Row(outline: outline, topicMarkdown: "Linking Row")
		outline.createRowsInsideAtEnd([headingRow, linkingRow], afterRowContainer: outline)

		try link(linkingRow, to: headingRow, text: "Jump")

		let markdown = outline.markdownDoc()

		#expect(markdown.contains("## My Heading"))
		#expect(markdown.contains("[Jump](#my-heading)"))
		#expect(!markdown.contains("zavala://row"))

		deleteAccountManager(accountManager)
	}

	@Test("Markdown Doc export leaves a Row Link to a non-heading Row alone")
	func rowLinkToNonHeadingRow() async throws {
		let accountManager = buildAccountManager()
		let outline = try buildOutline(accountManager: accountManager)

		let listRow = Row(outline: outline, topicMarkdown: "List Row")
		let linkingRow = Row(outline: outline, topicMarkdown: "Linking Row", noteMarkdown: "Linking note")
		outline.createRowsInsideAtEnd([listRow, linkingRow], afterRowContainer: outline)

		try link(linkingRow, to: listRow, text: "Jump")

		let markdown = outline.markdownDoc()

		#expect(!markdown.contains("(#list-row)"))
		#expect(markdown.contains("zavala://row"))

		deleteAccountManager(accountManager)
	}

	@Test("Markdown Doc export disambiguates links to repeated headings")
	func rowLinksToRepeatedHeadings() async throws {
		let accountManager = buildAccountManager()
		let outline = try buildOutline(accountManager: accountManager)

		let firstHeadingRow = Row(outline: outline, topicMarkdown: "My Heading", noteMarkdown: "First note")
		let secondHeadingRow = Row(outline: outline, topicMarkdown: "My Heading", noteMarkdown: "Second note")
		let linkingRow = Row(outline: outline, topicMarkdown: "Linking Row")
		outline.createRowsInsideAtEnd([firstHeadingRow, secondHeadingRow, linkingRow], afterRowContainer: outline)

		try link(firstHeadingRow, to: firstHeadingRow, text: "First")
		try link(secondHeadingRow, to: secondHeadingRow, text: "Second")

		let markdown = outline.markdownDoc()

		#expect(markdown.contains("[First](#my-heading)"))
		#expect(markdown.contains("[Second](#my-heading-1)"))

		deleteAccountManager(accountManager)
	}

	@Test("Heading slugs drop punctuation and replace spaces with hyphens")
	func headingSlugs() {
		#expect(MarkdownDocVisitor.slug(for: "My Heading") == "my-heading")
		#expect(MarkdownDocVisitor.slug(for: "  What's New, Zavala?!  ") == "whats-new-zavala")
		#expect(MarkdownDocVisitor.slug(for: "Snake_case and kebab-case") == "snake_case-and-kebab-case")
		#expect(MarkdownDocVisitor.slug(for: "!!!") == "")
	}

}

private extension MarkdownDocExportTests {

	func buildOutline(accountManager: AccountManager) throws -> Outline {
		let document = try #require(accountManager.localAccount?.createOutline(title: "Test Case"))
		let outline = try #require(document.outline)
		outline.load()
		return outline
	}

	/// Points the topic of `row` at `targetRow` the same way that a Row Link does.
	func link(_ row: Row, to targetRow: Row, text: String) throws {
		let url = try #require(targetRow.entityID.url)
		let topic = NSMutableAttributedString(string: text)
		topic.addAttribute(.link, value: url, range: NSRange(location: 0, length: topic.length))
		row.topic = topic
	}

}

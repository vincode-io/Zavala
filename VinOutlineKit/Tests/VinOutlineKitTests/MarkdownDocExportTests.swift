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
		let firstLinkingRow = Row(outline: outline, topicMarkdown: "First Link")
		let secondLinkingRow = Row(outline: outline, topicMarkdown: "Second Link")
		outline.createRowsInsideAtEnd([firstHeadingRow, secondHeadingRow, firstLinkingRow, secondLinkingRow], afterRowContainer: outline)

		try link(firstLinkingRow, to: firstHeadingRow, text: "First")
		try link(secondLinkingRow, to: secondHeadingRow, text: "Second")

		let markdown = outline.markdownDoc()

		#expect(markdown.contains("[First](#my-heading)"))
		#expect(markdown.contains("[Second](#my-heading-1)"))

		deleteAccountManager(accountManager)
	}

	@Test("Markdown Doc export links a Row Link to a heading Row in another outline when using alt links")
	func rowLinkToHeadingRowInOtherOutline() async throws {
		let accountManager = buildAccountManager()
		let outline = try buildOutline(accountManager: accountManager, title: "Linking Outline")
		let otherOutline = try buildOutline(accountManager: accountManager, title: "Other Outline")

		let otherHeadingRow = Row(outline: otherOutline, topicMarkdown: "Other Heading", noteMarkdown: "Other note")
		otherOutline.createRowsInsideAtEnd([otherHeadingRow], afterRowContainer: otherOutline)

		let linkingRow = Row(outline: outline, topicMarkdown: "Linking Row")
		outline.createRowsInsideAtEnd([linkingRow], afterRowContainer: outline)

		try link(linkingRow, to: otherHeadingRow, text: "Jump")

		#expect(outline.markdownDoc(useAltLinks: true).contains("[Jump](Other_Outline.md#other-heading)"))

		// Without alt links there is no reason to believe that the other outline was exported too.
		#expect(outline.markdownDoc().contains("zavala://row"))

		deleteAccountManager(accountManager)
	}

	@Test("Heading slugs drop punctuation and replace spaces with hyphens")
	func headingSlugs() {
		#expect(MarkdownDocHeadingLinks.slug(for: "My Heading") == "my-heading")
		#expect(MarkdownDocHeadingLinks.slug(for: "  What's New, Zavala?!  ") == "whats-new-zavala")
		#expect(MarkdownDocHeadingLinks.slug(for: "Snake_case and kebab-case") == "snake_case-and-kebab-case")
		#expect(MarkdownDocHeadingLinks.slug(for: "!!!") == "")
	}

}

private extension MarkdownDocExportTests {

	func buildOutline(accountManager: AccountManager, title: String = "Test Case") throws -> Outline {
		let document = try #require(accountManager.localAccount?.createOutline(title: title))
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

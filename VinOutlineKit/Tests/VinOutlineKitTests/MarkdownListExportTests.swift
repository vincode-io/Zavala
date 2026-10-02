//
//  Created by Maurice Parker on 10/2/26.
//

import Foundation
import Testing
@testable import VinOutlineKit

final class MarkdownListExportTests: VOKTestCase {

	@Test("Markdown List export writes a single paragraph topic on one line")
	func singleParagraphTopic() async throws {
		let accountManager = buildAccountManager()
		let outline = try buildOutline(accountManager: accountManager)

		let parentRow = Row(outline: outline, topicMarkdown: "Plan trip")
		let childRow = Row(outline: outline, topicMarkdown: "Book flights")
		outline.createRowsInsideAtEnd([parentRow], afterRowContainer: outline)
		outline.createRowsInsideAtEnd([childRow], afterRowContainer: parentRow)

		let markdown = outline.markdownList(format: true)

		#expect(markdown.contains("* Plan trip\n\t* Book flights"))

		deleteAccountManager(accountManager)
	}

	@Test("Markdown List export indents the continuation paragraphs of a topic under its list item")
	func multipleParagraphTopic() async throws {
		let accountManager = buildAccountManager()
		let outline = try buildOutline(accountManager: accountManager)

		let parentRow = Row(outline: outline, topicMarkdown: "Plan trip")
		let childRow = Row(outline: outline, topicMarkdown: "Book flights\n\nCheck both airlines")
		outline.createRowsInsideAtEnd([parentRow], afterRowContainer: outline)
		outline.createRowsInsideAtEnd([childRow], afterRowContainer: parentRow)

		let markdown = outline.markdownList(format: true)

		#expect(markdown.contains("\t* Book flights\n\n\t  Check both airlines"))
		#expect(!markdown.contains("\nCheck both airlines"))

		deleteAccountManager(accountManager)
	}

	@Test("Markdown List export strikes through each paragraph of a completed topic")
	func completedMultipleParagraphTopic() async throws {
		let accountManager = buildAccountManager()
		let outline = try buildOutline(accountManager: accountManager)

		let row = Row(outline: outline, topicMarkdown: "Book flights\n\nCheck both airlines")
		outline.createRowsInsideAtEnd([row], afterRowContainer: outline)
		outline.complete(rows: [row])

		let markdown = outline.markdownList(format: true)

		#expect(markdown.contains("* ~~Book flights~~\n\n  ~~Check both airlines~~"))

		deleteAccountManager(accountManager)
	}

	@Test("Markdown List export still indents notes under their list item")
	func topicWithNote() async throws {
		let accountManager = buildAccountManager()
		let outline = try buildOutline(accountManager: accountManager)

		let row = Row(outline: outline, topicMarkdown: "Book hotel", noteMarkdown: "Near the station")
		outline.createRowsInsideAtEnd([row], afterRowContainer: outline)

		let markdown = outline.markdownList(format: true)

		#expect(markdown.contains("* Book hotel\n\n  Near the station"))

		deleteAccountManager(accountManager)
	}

}

private extension MarkdownListExportTests {

	func buildOutline(accountManager: AccountManager, title: String = "Test Case") throws -> Outline {
		let document = try #require(accountManager.localAccount?.createOutline(title: title))
		let outline = try #require(document.outline)
		outline.load()
		return outline
	}

}

//
//  JoinRowTests.swift
//  ZavalaTests
//
//  Joining a row that has children is not allowed. The key press must do nothing,
//  and must not leave an undo step that changes the outline (issue #329).
//

import Foundation
import Testing
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Join row", .serialized)
struct JoinRowTests {

	private let outlineWithChildren = """
	- Alpha
	- Bravo
	  - B1
	"""

	@Test("Delete at the start of a row with children does nothing, and Undo doesn't duplicate the row")
	func deleteBackwardIntoRowWithChildren() async throws {
		let editor = try await EditorHarness.open(outlineWithChildren)

		try await editor.placeCursor(in: "Bravo", at: 0)
		try await editor.deleteBackward()

		expectUndoRedo(editor, before: outlineWithChildren, after: outlineWithChildren)
		await editor.close()
	}

	@Test("Forward Delete at the end of the row above a row with children does nothing, and Undo doesn't duplicate the row")
	func deleteForwardIntoRowWithChildren() async throws {
		let editor = try await EditorHarness.open(outlineWithChildren)

		try await editor.placeCursor(in: "Alpha", at: 5)
		try await editor.pressKey(.keyboardDeleteForward)

		expectUndoRedo(editor, before: outlineWithChildren, after: outlineWithChildren)
		await editor.close()
	}

}

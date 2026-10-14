//
//  TypingUndoTests.swift
//  ZavalaTests
//
//  Typing right before Return or Tab must be its own undo step, undone after the
//  structural edit and not together with it (issue #341).
//

import Foundation
import Testing
import UIKit
@testable import VinOutlineKit
@testable import Zavala

@MainActor
@Suite("Typing undo", .serialized)
struct TypingUndoTests {

	/// Checks the outline, and that every row's cell shows its row's current text.
	private func expectState(_ editor: EditorHarness, _ expected: String, sourceLocation: SourceLocation) async {
		await editor.settle()
		expectOutline(editor.outline, expected, sourceLocation: sourceLocation)
		#expect(editor.displayedTopics == editor.visibleTitles, "A cell isn't showing its row's text", sourceLocation: sourceLocation)
	}

	/// Undoes twice, checking the outline after each step, then redoes twice back to `after`.
	private func expectTwoUndoSteps(_ editor: EditorHarness, original: String, typed: String, after: String, sourceLocation: SourceLocation = #_sourceLocation) async {
		await expectState(editor, after, sourceLocation: sourceLocation)
		// Cmd-Z goes to the focused row's undo manager first, which only falls back to the editor's.
		guard let undoManager = editor.focusedUndoManager ?? editor.editor.undoManager else {
			Issue.record("The editor has no undo manager", sourceLocation: sourceLocation)
			return
		}
		undoManager.undo()
		await expectState(editor, typed, sourceLocation: sourceLocation)
		undoManager.undo()
		await expectState(editor, original, sourceLocation: sourceLocation)
		undoManager.redo()
		await expectState(editor, typed, sourceLocation: sourceLocation)
		undoManager.redo()
		await expectState(editor, after, sourceLocation: sourceLocation)
	}

	@Test("Typing then Return at the end of a row: Undo removes the new row, then the typing")
	func typingThenReturnAtEnd() async throws {
		let original = """
		- Alpha
		- Bravo
		"""
		let editor = try await EditorHarness.open(original)

		try await editor.placeCursor(in: "Alpha", at: 5)
		try await editor.type("!")
		try await editor.type("\n")

		await expectTwoUndoSteps(editor, original: original, typed: """
		- Alpha!
		- Bravo
		""", after: """
		- Alpha!
		-
		- Bravo
		""")
		await editor.close()
	}

	@Test("Typing then Return in the middle of a row: Undo rejoins the row, then removes the typing")
	func typingThenReturnInMiddle() async throws {
		let original = """
		- Alpha
		- Bravo
		"""
		let editor = try await EditorHarness.open(original)

		try await editor.placeCursor(in: "Alpha", at: 2)
		try await editor.type("!")
		try await editor.type("\n")

		await expectTwoUndoSteps(editor, original: original, typed: """
		- Al!pha
		- Bravo
		""", after: """
		- Al!
		- pha
		- Bravo
		""")
		await editor.close()
	}

	@Test("Typing then Tab: Undo outdents the row and keeps the typing, then removes the typing")
	func typingThenTab() async throws {
		let original = """
		- Alpha
		- Bravo
		- Charlie
		"""
		let editor = try await EditorHarness.open(original)

		try await editor.placeCursor(in: "Bravo", at: 5)
		try await editor.type("!")
		// Tab is handled by the editor's key command, not the row's text view.
		try await editor.press("\t")

		await expectTwoUndoSteps(editor, original: original, typed: """
		- Alpha
		- Bravo!
		- Charlie
		""", after: """
		- Alpha
		  - Bravo!
		- Charlie
		""")
		await editor.close()
	}

	@Test("Typing then Shift-Tab: Undo indents the row and keeps the typing, then removes the typing")
	func typingThenShiftTab() async throws {
		let original = """
		- Alpha
		  - Bravo
		- Charlie
		"""
		let editor = try await EditorHarness.open(original)

		try await editor.placeCursor(in: "Bravo", at: 5)
		try await editor.type("!")
		try await editor.press("\t", [.shift])

		await expectTwoUndoSteps(editor, original: original, typed: """
		- Alpha
		  - Bravo!
		- Charlie
		""", after: """
		- Alpha
		- Bravo!
		- Charlie
		""")
		await editor.close()
	}

	@Test("Typing then Move Up: Undo moves the row back down and keeps the typing, then removes the typing")
	func typingThenMoveUp() async throws {
		let original = """
		- Alpha
		- Bravo
		- Charlie
		"""
		let editor = try await EditorHarness.open(original)

		try await editor.placeCursor(in: "Bravo", at: 5)
		try await editor.type("!")
		try await editor.pressMenu(UIKeyCommand.inputUpArrow, [.control, .command])

		await expectTwoUndoSteps(editor, original: original, typed: """
		- Alpha
		- Bravo!
		- Charlie
		""", after: """
		- Bravo!
		- Alpha
		- Charlie
		""")
		await editor.close()
	}

	@Test("Typing then Move Down: Undo moves the row back up and keeps the typing, then removes the typing")
	func typingThenMoveDown() async throws {
		let original = """
		- Alpha
		- Bravo
		- Charlie
		"""
		let editor = try await EditorHarness.open(original)

		try await editor.placeCursor(in: "Bravo", at: 5)
		try await editor.type("!")
		try await editor.pressMenu(UIKeyCommand.inputDownArrow, [.control, .command])

		await expectTwoUndoSteps(editor, original: original, typed: """
		- Alpha
		- Bravo!
		- Charlie
		""", after: """
		- Alpha
		- Charlie
		- Bravo!
		""")
		await editor.close()
	}

}

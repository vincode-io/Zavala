//
//  EditorExpectations.swift
//  ZavalaTests
//

import Foundation
import Testing
@testable import VinOutlineKit
@testable import Zavala

/// Same comparison as VinOutlineKitTests' expectOutline, for editor tests.
@MainActor
func expectOutline(_ outline: Outline, _ expected: String, sourceLocation: SourceLocation = #_sourceLocation) {
	let actual = OutlineSnapshot.render(OutlineSnapshot.nodes(from: outline))
	do {
		if let report = OutlineSnapshot.diff(expected: try OutlineSnapshot.normalize(expected), actual: actual) {
			Issue.record(Comment(rawValue: report), sourceLocation: sourceLocation)
		}
	} catch {
		Issue.record(error, sourceLocation: sourceLocation)
	}
}

/// Checks the outline right after an edit, after the editor's Undo, and after its Redo.
@MainActor
func expectUndoRedo(_ editor: EditorHarness, before: String, after: String, sourceLocation: SourceLocation = #_sourceLocation) {
	expectOutline(editor.outline, after, sourceLocation: sourceLocation)
	guard let undoManager = editor.editor.undoManager else {
		Issue.record("The editor has no undo manager", sourceLocation: sourceLocation)
		return
	}
	undoManager.undo()
	expectOutline(editor.outline, before, sourceLocation: sourceLocation)
	undoManager.redo()
	expectOutline(editor.outline, after, sourceLocation: sourceLocation)
}

/// Checks a row's topic as Markdown, since formatting isn't part of the outline DSL.
@MainActor
func expectTopicMarkdown(_ editor: EditorHarness, _ title: String, _ expected: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
	let row = try editor.outline.row(titled: title, sourceLocation: sourceLocation)
	#expect(row.topic?.markdownRepresentation == expected, sourceLocation: sourceLocation)
}

/// Checks a formatting change made just before this call, with Undo and Redo run straight after it, as Cmd-Z is.
/// The text on screen is checked at each step. The row is saved last: saving registers an undo step of its own,
/// so saving first would make Undo revert the save instead of the formatting (ED-276 covers that order).
@MainActor
func expectFormatUndoRedo(_ editor: EditorHarness, _ title: String, before: String, after: String, sourceLocation: SourceLocation = #_sourceLocation) async throws {
	#expect(editor.focusedTextMarkdown == after, sourceLocation: sourceLocation)
	guard let undoManager = editor.focusedUndoManager else {
		Issue.record("The focused row has no undo manager", sourceLocation: sourceLocation)
		return
	}
	undoManager.undo()
	#expect(editor.focusedTextMarkdown == before, sourceLocation: sourceLocation)
	undoManager.redo()
	#expect(editor.focusedTextMarkdown == after, sourceLocation: sourceLocation)
	try await editor.commitTyping(sourceLocation: sourceLocation)
	try expectTopicMarkdown(editor, title, after, sourceLocation: sourceLocation)
}

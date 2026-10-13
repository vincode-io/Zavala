import Foundation
import Testing
@testable import VinOutlineKit

final class DeleteRowCommandTests: VOKTestCase {
	
    @Test("DeleteRowCommand deletes a row and is undoable")
    func deleteRowAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        let originalCount = outline.rows.count
		
		let command = DeleteRowCommand(actionName: "DeleteRow", undoManager: undoManager, delegate: self, outline: outline, rows: [row], currentRow: nil, rowStrings: nil, isInOutlineMode: false)
        command.execute()
        #expect(outline.rows.count == originalCount - 1)
		
        undoManager.undo()
        #expect(outline.rows.count == originalCount)
		
        undoManager.redo()
        #expect(outline.rows.count == originalCount - 1)
		
        deleteAccountManager(accountManager)
    }

	@Test("Undoing the delete of a collapsed row restores its hidden children under it")
	func deleteCollapsedRowAndUndo() async throws {
		let before = """
			- A
			  - A1
			  - A2
			    - A2a
			- (+) B
			  - B1
			    - B1a
			  - B2
			- C
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		let command = DeleteRowCommand(actionName: "DeleteRow", undoManager: undoManager, delegate: self, outline: outline, rows: [try outline.row(titled: "B")], currentRow: nil, rowStrings: nil, isInOutlineMode: false)
		command.execute()

		expectEdit(outline, before: before, after: """
			- A
			  - A1
			  - A2
			    - A2a
			- C
			""")
	}

	@Test("Undoing the delete of nested and sibling rows puts each back in place")
	func deleteMultipleRowsAndUndo() async throws {
		let before = """
			- A
			  - A1
			  - (+) A2
			    - A2a
			  - A3
			- B
			- C
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		let rows = [try outline.row(titled: "C"), try outline.row(titled: "A2"), try outline.row(titled: "A1")]
		let command = DeleteRowCommand(actionName: "DeleteRow", undoManager: undoManager, delegate: self, outline: outline, rows: rows, currentRow: nil, rowStrings: nil, isInOutlineMode: true)
		command.execute()

		expectEdit(outline, before: before, after: """
			- A
			  - A3
			- B
			""")
	}

	@Test("Deleting multiple rows in outline mode selects the row that takes the first deleted row's place")
	@MainActor
	func deleteMultipleRowsSelectsFirstDeletedPosition() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- Alpha
			- Bravo
			- Charlie
			- Delta
			""")
		defer { deleteAccountManager(accountManager) }

		let recorder = SelectIndexRecorder()
		let observer = NotificationCenter.default.addObserver(forName: .OutlineElementsDidChange, object: outline, queue: nil) { note in
			let newSelectIndex = (note.userInfo?[OutlineElementChanges.userInfoKey] as? OutlineElementChanges)?.newSelectIndex
			MainActor.assumeIsolated {
				recorder.newSelectIndex = newSelectIndex ?? recorder.newSelectIndex
			}
		}
		defer { NotificationCenter.default.removeObserver(observer) }

		// Pass the rows out of display order so the selection can't depend on the order they're given in.
		let rows = [try outline.row(titled: "Charlie"), try outline.row(titled: "Alpha")]
		let command = DeleteRowCommand(actionName: "DeleteRow", undoManager: undoManager, delegate: self, outline: outline, rows: rows, currentRow: nil, rowStrings: nil, isInOutlineMode: true)
		command.execute()

		let newSelectIndex = try #require(recorder.newSelectIndex)
		#expect(outline.shadowTable?[newSelectIndex] === (try outline.row(titled: "Bravo")))
	}

	@Test("Undoing a delete doesn't auto complete the restored row's parent")
	func deleteCompletedChildAndUndo() async throws {
		let before = """
			- Alpha
			  - [x] A1
			- [x] Bravo
			  - B1
			- Charlie
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		let rows = [try outline.row(titled: "A1"), try outline.row(titled: "Bravo")]
		let command = DeleteRowCommand(actionName: "DeleteRow", undoManager: undoManager, delegate: self, outline: outline, rows: rows, currentRow: nil, rowStrings: nil, isInOutlineMode: true)
		command.execute()

		expectEdit(outline, before: before, after: """
			- Alpha
			- Charlie
			""")
	}

	@Test("Undoing a delete doesn't auto uncomplete the restored row's parent")
	func deleteUncompletedChildAndUndo() async throws {
		let before = """
			- [x] Alpha
			  - A1
			- Bravo
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		let command = DeleteRowCommand(actionName: "DeleteRow", undoManager: undoManager, delegate: self, outline: outline, rows: [try outline.row(titled: "A1")], currentRow: nil, rowStrings: nil, isInOutlineMode: true)
		command.execute()

		expectEdit(outline, before: before, after: """
			- [x] Alpha
			- Bravo
			""")
	}

	@Test("Undoing a delete restores a parent that was auto completed by the delete")
	func deleteLastUncompletedChildAndUndo() async throws {
		let before = """
			- Alpha
			  - [x] A1
			  - A2
			- Bravo
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		let command = DeleteRowCommand(actionName: "DeleteRow", undoManager: undoManager, delegate: self, outline: outline, rows: [try outline.row(titled: "A2")], currentRow: nil, rowStrings: nil, isInOutlineMode: true)
		command.execute()

		expectEdit(outline, before: before, after: """
			- [x] Alpha
			  - [x] A1
			- Bravo
			""")
	}
}

/// Captures the selection index from the `OutlineElementsDidChange` notifications an outline posts.
@MainActor
private final class SelectIndexRecorder {
	var newSelectIndex: Int?
}

import Foundation
import Testing
@testable import VinOutlineKit

final class CutRowCommandTests: VOKTestCase {
    @Test("CutRowCommand cuts a row and is undoable")
    func cutRowAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        let originalCount = outline.rows.count
		
        let command = CutRowCommand(actionName: "CutRow", undoManager: undoManager, delegate: self, outline: outline, rows: [row], isInOutlineMode: true)
        command.execute()
        #expect(!outline.rows.contains(row))
		
        undoManager.undo()
        #expect(outline.rows.contains(row))
		
        undoManager.redo()
        #expect(!outline.rows.contains(row))
        deleteAccountManager(accountManager)
    }

	@Test("Undoing a cut restores a row whose row above was another cut row's child")
	func cutRowAfterCutChildAndUndo() async throws {
		let before = """
			- Alpha
			- Bravo
			  - B1
			- Charlie
			- Delta
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		let rows = [try outline.row(titled: "Bravo"), try outline.row(titled: "Charlie")]
		let command = CutRowCommand(actionName: "CutRow", undoManager: undoManager, delegate: self, outline: outline, rows: rows, isInOutlineMode: true)
		command.execute()

		expectEdit(outline, before: before, after: """
			- Alpha
			- Delta
			""")
	}

	@Test("Undoing the cut of a collapsed row restores its hidden children under it")
	func cutCollapsedRowAndUndo() async throws {
		let before = """
			- A
			- (+) B
			  - B1
			    - B1a
			  - B2
			- C
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		let command = CutRowCommand(actionName: "CutRow", undoManager: undoManager, delegate: self, outline: outline, rows: [try outline.row(titled: "B")], isInOutlineMode: true)
		command.execute()

		expectEdit(outline, before: before, after: """
			- A
			- C
			""")
	}

	@Test("Undoing a cut doesn't auto complete the restored row's parent")
	func cutCompletedChildAndUndo() async throws {
		let before = """
			- Alpha
			  - [x] A1
			- Bravo
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		let command = CutRowCommand(actionName: "CutRow", undoManager: undoManager, delegate: self, outline: outline, rows: [try outline.row(titled: "A1")], isInOutlineMode: true)
		command.execute()

		expectEdit(outline, before: before, after: """
			- Alpha
			- Bravo
			""")
	}
}


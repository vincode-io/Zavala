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
}

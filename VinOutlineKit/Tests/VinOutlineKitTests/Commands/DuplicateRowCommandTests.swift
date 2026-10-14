import Foundation
import Testing
@testable import VinOutlineKit

final class DuplicateRowCommandTests: VOKTestCase {
    @Test("DuplicateRowCommand duplicates a row and is undoable")
    func duplicateRowAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        let originalCount = outline.rows.count
        let command = DuplicateRowCommand(actionName: "DuplicateRow", undoManager: undoManager, delegate: self, outline: outline, rows: [row])
        command.execute()
        #expect(outline.rows.count == originalCount + 1)
        undoManager.undo()
        #expect(outline.rows.count == originalCount)
        undoManager.redo()
        #expect(outline.rows.count == originalCount + 1)
        deleteAccountManager(accountManager)
    }

	@Test("Redoing a duplicate of multiple rows puts the copies after the last selected row")
	func duplicateMultipleRowsAndRedo() async throws {
		let before = """
			- A
			- B
			  > b note
			  - B1
			- [x] C
			- D
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		let rows = [try outline.row(titled: "B"), try outline.row(titled: "C")]
		let command = DuplicateRowCommand(actionName: "DuplicateRow", undoManager: undoManager, delegate: self, outline: outline, rows: rows)
		command.execute()

		expectEdit(outline, before: before, after: """
			- A
			- B
			  > b note
			  - B1
			- [x] C
			- B
			  > b note
			  - B1
			- [x] C
			- D
			""")
	}
}

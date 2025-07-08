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
		
        let command = DeleteRowCommand(actionName: "DeleteRow", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: row.rowStrings, isInOutlineMode: false)
        command.execute()
        #expect(outline.rows.count == originalCount - 1)
		
        undoManager.undo()
        #expect(outline.rows.count == originalCount)
		
        undoManager.redo()
        #expect(outline.rows.count == originalCount - 1)
		
        deleteAccountManager(accountManager)
    }
}

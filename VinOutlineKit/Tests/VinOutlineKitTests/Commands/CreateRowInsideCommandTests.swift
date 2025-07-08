import Foundation
import Testing
@testable import VinOutlineKit

final class CreateRowInsideCommandTests: VOKTestCase {
	
    @Test("CreateRowInsideCommand creates a row inside and is undoable")
    func createRowInsideAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let parentRow = try #require(outline.rows.first)
        let originalChildCount = parentRow.rowCount
		
        let command = CreateRowInsideCommand(actionName: "CreateInside", undoManager: undoManager, delegate: self, outline: outline, afterRow: parentRow, rowStrings: nil)
        command.execute()
        #expect(parentRow.rowCount == originalChildCount + 1)
		
        undoManager.undo()
        #expect(parentRow.rowCount == originalChildCount)
		
        undoManager.redo()
        #expect(parentRow.rowCount == originalChildCount + 1)
		
        deleteAccountManager(accountManager)
    }
	
}


import Foundation
import Testing
@testable import VinOutlineKit

final class CreateRowBeforeCommandTests: VOKTestCase {
	
    @Test("CreateRowBeforeCommand creates a row before and is undoable")
    func createRowBeforeAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let beforeRow = try #require(outline.rows.first)
        let originalCount = outline.rows.count
        let command = CreateRowBeforeCommand(actionName: "CreateBefore", undoManager: undoManager, delegate: self, outline: outline, beforeRow: beforeRow, rowStrings: nil, moveCursor: true)
        command.execute()
        #expect(outline.rows.count == originalCount + 1)
        #expect(outline.rows.first !== beforeRow)
        undoManager.undo()
        #expect(outline.rows.count == originalCount)
        undoManager.redo()
        #expect(outline.rows.count == originalCount + 1)
        deleteAccountManager(accountManager)
    }
	
}

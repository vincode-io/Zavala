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
}


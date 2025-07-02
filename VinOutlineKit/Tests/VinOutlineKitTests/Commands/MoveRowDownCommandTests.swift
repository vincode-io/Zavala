import Foundation
import Testing
@testable import VinOutlineKit

final class MoveRowDownCommandTests: VOKTestCase {
	
    @Test("MoveRowDownCommand moves row down and is undoable")
    func moveDownAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        if outline.rows.count < 2 { return }
        let row = outline.rows[0]
        let command = MoveRowDownCommand(actionName: "MoveDown", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: nil)
        let originalIndex = outline.rows.firstIndex(of: row)
        command.execute()
        #expect(outline.rows.firstIndex(of: row) == originalIndex! + 1)
        undoManager.undo()
        #expect(outline.rows.firstIndex(of: row) == originalIndex)
        deleteAccountManager(accountManager)
    }
	
}

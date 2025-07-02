import Foundation
import Testing
@testable import VinOutlineKit

final class MoveRowUpCommandTests: VOKTestCase {
	
    @Test("MoveRowUpCommand moves row up and is undoable")
    func moveUpAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        if outline.rows.count < 2 { return }
        let row = outline.rows[1]
        let rowAbove = outline.rows[0]
        let command = MoveRowUpCommand(actionName: "MoveUp", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: nil)
        let originalIndex = outline.rows.firstIndex(of: row)
        command.execute()
        #expect(outline.rows.firstIndex(of: row) == originalIndex! - 1)
        undoManager.undo()
        #expect(outline.rows.firstIndex(of: row) == originalIndex)
        deleteAccountManager(accountManager)
    }
	
}

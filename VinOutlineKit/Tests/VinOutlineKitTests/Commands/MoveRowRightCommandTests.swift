import Foundation
import Testing
@testable import VinOutlineKit

final class MoveRowRightCommandTests: VOKTestCase {
	
    @Test("MoveRowRightCommand moves row right and is undoable")
    func moveRightAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.last)
        let command = MoveRowRightCommand(actionName: "MoveRight", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: nil)
        command.execute()
        #expect(row.trueLevel > 0)
        undoManager.undo()
        #expect(row.trueLevel == 0)
        deleteAccountManager(accountManager)
    }
	
}

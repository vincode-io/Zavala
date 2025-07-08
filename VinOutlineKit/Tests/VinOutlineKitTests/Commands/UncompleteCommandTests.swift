import Foundation
import Testing
@testable import VinOutlineKit

final class UncompleteCommandTests: VOKTestCase {
	
    @Test("UncompleteCommand marks row incomplete and is undoable")
    func uncompleteAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        row.isComplete = true
		
		let command = UncompleteCommand(actionName: "Uncomplete", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: nil)
        command.execute()
        #expect(row.isComplete == false)
		
        undoManager.undo()
        #expect(row.isComplete == true)
		
        undoManager.redo()
        #expect(row.isComplete == false)
		
        deleteAccountManager(accountManager)
    }
}

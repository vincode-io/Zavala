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

	@Test("Undoing UncompleteCommand leaves rows that were already incomplete incomplete")
	func undoLeavesAlreadyUncompletedRowsUncomplete() async throws {
		let accountManager = buildAccountManager()
		let undoManager = UndoManager()
		let outline = try await loadOutline(accountManager: accountManager)
		let alpha = outline.rows[0]
		let bravo = outline.rows[1]
		alpha.isComplete = true

		let command = UncompleteCommand(actionName: "Uncomplete", undoManager: undoManager, delegate: self, outline: outline, rows: [alpha, bravo], rowStrings: nil)
		command.execute()
		#expect(alpha.isComplete == false)
		#expect(bravo.isComplete == false)

		undoManager.undo()
		#expect(alpha.isComplete == true)
		#expect(bravo.isComplete == false)

		undoManager.redo()
		#expect(alpha.isComplete == false)
		#expect(bravo.isComplete == false)

		deleteAccountManager(accountManager)
	}
}

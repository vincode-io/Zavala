import Foundation
import Testing
@testable import VinOutlineKit

final class MoveRowRightCommandTests: VOKTestCase {
	
    @Test("MoveRowRightCommand moves a row right and is undoable")
    func moveRowRightAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.last)
        let moveRightRow = Row(outline: outline)
        outline.createRow(moveRightRow, afterRow: row, rowStrings: nil)
        let command = MoveRowRightCommand(actionName: "MoveRight", undoManager: undoManager, delegate: self, outline: outline, rows: [moveRightRow], rowStrings: nil)
        
		command.execute()
        #expect(moveRightRow.parent === row)
		#expect(moveRightRow.trueLevel > 0)

		undoManager.undo()
        #expect(moveRightRow.parent === outline)
		#expect(moveRightRow.trueLevel == 0)
        
		undoManager.redo()
        #expect(moveRightRow.parent === row)
		#expect(moveRightRow.trueLevel > 0)
		
        deleteAccountManager(accountManager)
    }
	
}

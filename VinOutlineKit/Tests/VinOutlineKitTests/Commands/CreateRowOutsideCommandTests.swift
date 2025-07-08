import Foundation
import Testing
@testable import VinOutlineKit

final class CreateRowOutsideCommandTests: VOKTestCase {
	
    @Test("CreateRowOutsideCommand creates a row outside and is undoable")
    func createRowOutsideAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
		let parentRow = try #require(outline.rows.first?.rows.first)
        let child = Row(outline: outline)
        outline.createRow(child, afterRow: parentRow, rowStrings: nil)
        let originalCount = outline.rows.count
		
		let command = CreateRowOutsideCommand(actionName: "CreateOutside", undoManager: undoManager, delegate: self, outline: outline, afterRow: parentRow, rowStrings: nil)
        command.execute()
        #expect(outline.rows.count == originalCount + 1)
		
        undoManager.undo()
        #expect(outline.rows.count == originalCount)
		
        undoManager.redo()
        #expect(outline.rows.count == originalCount + 1)
		
        deleteAccountManager(accountManager)
    }
	
}

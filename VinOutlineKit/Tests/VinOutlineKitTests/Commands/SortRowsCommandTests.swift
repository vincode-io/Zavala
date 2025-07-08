import Foundation
import Testing
@testable import VinOutlineKit

final class SortRowsCommandTests: VOKTestCase {
	
    @Test("SortRowsCommand sorts rows and is undoable")
    func sortRowsAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row1 = try #require(outline.rows.last)
        let row2 = Row(outline: outline)
		row2.topic = NSAttributedString(string: "Test 0")
		outline.createRow(row2, afterRow: row1, rowStrings: nil)
		
        let command = SortRowsCommand(actionName: "SortRows", undoManager: undoManager, delegate: self, outline: outline, rows: [row1, row2])
        command.execute()
		#expect(outline.rows.last?.topic?.string == "Test 6")
		
        undoManager.undo()
		#expect(outline.rows.last?.topic?.string == "Test 0")

        undoManager.redo()
		#expect(outline.rows.last?.topic?.string == "Test 6")

        deleteAccountManager(accountManager)
    }
	
}

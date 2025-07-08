import Foundation
import Testing
@testable import VinOutlineKit

final class SplitRowCommandTests: VOKTestCase {
	
    @Test("SplitRowCommand splits a row and is undoable")
    func splitRowAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.last)
        let attrString = NSAttributedString(string: "hello world")
		let originalRowCount = outline.rowCount
		
		let command = SplitRowCommand(actionName: "SplitRow", undoManager: undoManager, delegate: self, outline: outline, row: row, topic: attrString, cursorPosition: 5)
        command.execute()
		#expect(outline.rows.count == originalRowCount + 1)
		#expect(outline.rows[outline.rows.count - 2].topic?.string == "hello")
		#expect(outline.rows[outline.rows.count - 1].topic?.string == " world")

        undoManager.undo()
		#expect(outline.rows.count == originalRowCount)
		#expect(outline.rows[outline.rows.count - 1].topic?.string == "hello world")

        undoManager.redo()
		#expect(outline.rows.count == originalRowCount + 1)
		#expect(outline.rows[outline.rows.count - 2].topic?.string == "hello")
		#expect(outline.rows[outline.rows.count - 1].topic?.string == " world")

        deleteAccountManager(accountManager)
    }
	
}


import Foundation
import Testing
@testable import VinOutlineKit

final class PasteRowCommandTests: VOKTestCase {
	
    @Test("PasteRowCommand pastes a row and is undoable")
    func pasteRowAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.last)
        let pasteRow = Row(outline: outline)
		pasteRow.topic = NSAttributedString(string: "Test Row")
        let rowGroup = RowGroup(pasteRow)
		
		let command = PasteRowCommand(actionName: "PasteRow",
									  undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rowGroups: [rowGroup],
									  afterRow: row,
									  childRowIndent: true)
        command.execute()
		#expect(outline.rows.last?.topic?.string == "Test Row")
		
        undoManager.undo()
		#expect(outline.rows.last?.topic?.string == "Test 6")

        undoManager.redo()
		#expect(outline.rows.last?.topic?.string == "Test Row")

        deleteAccountManager(accountManager)
    }
}

import Foundation
import Testing
@testable import VinOutlineKit

final class GroupRowsCommandTests: VOKTestCase {
	
    @Test("GroupRowsCommand groups rows and is undoable")
    func groupRowsAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let first = outline.rows[4]
        let second = outline.rows[5]
		
        let command = GroupRowsCommand(actionName: "GroupRows", undoManager: undoManager, delegate: self, outline: outline, rows: [first, second], rowStrings: nil)
        command.execute()
		#expect(outline.rows[4].rowCount == 2)
		#expect(outline.rows[4] == first.parent as? Row)
		#expect(outline.rows[4] == second.parent as? Row)
		
        undoManager.undo()
		#expect(outline.rows[4].rowCount == 0)
		
        undoManager.redo()
		#expect(outline.rows[4].rowCount == 2)
		
        deleteAccountManager(accountManager)
    }
	
}

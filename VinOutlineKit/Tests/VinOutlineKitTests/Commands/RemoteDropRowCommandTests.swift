import Foundation
import Testing
@testable import VinOutlineKit

final class RemoteDropRowCommandTests: VOKTestCase {
	
    @Test("RemoteDropRowCommand drops a remote row and is undoable")
    func remoteDropRowAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let afterRow = try #require(outline.rows.last)
		let origingalRowCount = outline.rowCount
		
		let row = Row(outline: outline, topicMarkdown: "This is a test.")
        let rowGroup = RowGroup(row)
		
        let command = RemoteDropRowCommand(actionName: "RemoteDropRow", undoManager: undoManager, delegate: self, outline: outline, rowGroups: [rowGroup], afterRow: afterRow, prefersEnd: false, afterRowIsNewParent: false)
        command.execute()
		#expect(origingalRowCount + 1 == outline.rows.count)
		#expect(outline.rows.last?.topic?.string == "This is a test.")
		
        undoManager.undo()
		#expect(origingalRowCount == outline.rows.count)
		#expect(outline.rows.last?.topic?.string == "Test 6")

        undoManager.redo()
		#expect(origingalRowCount + 1 == outline.rows.count)
		#expect(outline.rows.last?.topic?.string == "This is a test.")

        deleteAccountManager(accountManager)
    }
	
}

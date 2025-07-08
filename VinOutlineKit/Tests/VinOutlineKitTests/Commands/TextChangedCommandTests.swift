import Foundation
import Testing
@testable import VinOutlineKit

final class TextChangedCommandTests: VOKTestCase {
	
    @Test("TextChangedCommand changes text and is undoable")
    func textChangedAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        let oldText = row.topic?.string
        let newText = NSAttributedString(string: "Changed")
		
        let command = TextChangedCommand(actionName: "TextChanged", undoManager: undoManager, delegate: self, outline: outline, row: row, rowStrings: RowStrings.topic(newText), isInNotes: false, selection: NSRange(location: 0, length: 0))
        command.execute()
        #expect(row.topic?.string == "Changed")
		
        undoManager.undo()
        #expect(row.topic?.string == oldText)
		
        undoManager.redo()
        #expect(row.topic?.string == "Changed")
		
        deleteAccountManager(accountManager)
    }
}


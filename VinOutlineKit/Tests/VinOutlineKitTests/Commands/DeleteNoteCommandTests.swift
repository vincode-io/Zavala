import Foundation
import Testing
@testable import VinOutlineKit

final class DeleteNoteCommandTests: VOKTestCase {
	
    @Test("DeleteNoteCommand deletes a note and is undoable")
    func deleteNoteAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        let note = NSAttributedString(string: "Test Note")
        row.note = note
		
        let command = DeleteNoteCommand(actionName: "DeleteNote", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: nil)
        command.execute()
        #expect(row.note == nil)
		
        undoManager.undo()
        #expect(row.note?.string == "Test Note")
		
        undoManager.redo()
        #expect(row.note == nil)
		
        deleteAccountManager(accountManager)
    }
	
}

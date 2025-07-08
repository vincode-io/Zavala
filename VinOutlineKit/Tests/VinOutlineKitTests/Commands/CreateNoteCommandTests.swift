import Foundation
import Testing
@testable import VinOutlineKit

final class CreateNoteCommandTests: VOKTestCase {
	
    @Test("CreateNoteCommand adds a note and is undoable")
    func createNoteAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        #expect(row.note == nil)
		
		let command = CreateNoteCommand(actionName: "CreateNote", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: nil)
        command.execute()
        #expect(row.note?.string == "")

        undoManager.undo()
        #expect(row.note == nil)

        undoManager.redo()
        #expect(row.note?.string == "")
        deleteAccountManager(accountManager)
    }
	
}

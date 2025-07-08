import Foundation
import Testing
@testable import VinOutlineKit

final class CreateRowAfterCommandTests: VOKTestCase {
	
    @Test("CreateRowAfterCommand creates row after and is undoable")
	
    func createAfterAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let afterRow = try #require(outline.rows.first)
        let command = CreateRowAfterCommand(actionName: "CreateAfter", undoManager: undoManager, delegate: self, outline: outline, afterRow: afterRow, rowStrings: nil)
		let originalCount = outline.rows.first?.rowCount ?? 0
        command.execute()
        #expect(outline.rows.first?.rowCount ?? 0 == originalCount + 1)
        undoManager.undo()
        #expect(outline.rows.first?.rowCount ?? 0 == originalCount)
        deleteAccountManager(accountManager)
    }
	
}

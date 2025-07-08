import Foundation
import Testing
@testable import VinOutlineKit

final class DuplicateRowCommandTests: VOKTestCase {
    @Test("DuplicateRowCommand duplicates a row and is undoable")
    func duplicateRowAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        let originalCount = outline.rows.count
        let command = DuplicateRowCommand(actionName: "DuplicateRow", undoManager: undoManager, delegate: self, outline: outline, rows: [row])
        command.execute()
        #expect(outline.rows.count == originalCount + 1)
        undoManager.undo()
        #expect(outline.rows.count == originalCount)
        undoManager.redo()
        #expect(outline.rows.count == originalCount + 1)
        deleteAccountManager(accountManager)
    }
}

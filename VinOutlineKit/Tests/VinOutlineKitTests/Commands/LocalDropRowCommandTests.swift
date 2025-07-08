import Foundation
import Testing
@testable import VinOutlineKit

final class LocalDropRowCommandTests: VOKTestCase {
    @Test("LocalDropRowCommand drops rows locally and is undoable")
    func localDropRowAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let parentRow = try #require(outline.rows.first)
        let child = Row(outline: outline)
        outline.createRow(child, afterRow: parentRow, rowStrings: nil)
        let command = LocalDropRowCommand(actionName: "LocalDropRow", undoManager: undoManager, delegate: self, outline: outline, rows: [child], toParent: outline, toChildIndex: 0)
        command.execute()
        #expect(child.parent === outline)
        undoManager.undo()
        #expect(child.parent === parentRow)
        undoManager.redo()
        #expect(child.parent === outline)
        deleteAccountManager(accountManager)
    }
}

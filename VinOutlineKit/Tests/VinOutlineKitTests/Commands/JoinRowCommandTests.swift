import Foundation
import Testing
@testable import VinOutlineKit

final class JoinRowCommandTests: VOKTestCase {
	
    @Test("JoinRowCommand joins rows and is undoable")
    func joinRowsAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        guard outline.rows.count > 1 else { return }
        let upper = outline.rows[0]
        let topic = (upper.topic ?? NSAttributedString()).mutableCopy() as! NSMutableAttributedString
        let lower = outline.rows[1]
        let command = JoinRowCommand(
            actionName: "JoinRow",
            undoManager: undoManager,
            delegate: self,
            outline: outline,
            topRow: upper,
            bottomRow: lower,
            topic: topic
        )
        command.execute()
        #expect(outline.rows.contains(upper))
        #expect(!outline.rows.contains(lower))
        undoManager.undo()
        #expect(outline.rows.contains(lower))
        undoManager.redo()
        #expect(!outline.rows.contains(lower))
        deleteAccountManager(accountManager)
    }
	
}

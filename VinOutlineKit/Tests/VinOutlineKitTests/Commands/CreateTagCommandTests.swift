import Foundation
import Testing
@testable import VinOutlineKit

final class CreateTagCommandTests: VOKTestCase {
    @Test("CreateTagCommand creates a tag and is undoable")
    func createTagAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let originalTagCount = outline.tags.count
        let tagName = "TestTag"
        let command = CreateTagCommand(actionName: "CreateTag", undoManager: undoManager, delegate: self, outline: outline, tagName: tagName)
        command.execute()
        #expect(outline.tags.contains(where: { $0.name == tagName }))
        undoManager.undo()
        #expect(!outline.tags.contains(where: { $0.name == tagName }))
        undoManager.redo()
        #expect(outline.tags.contains(where: { $0.name == tagName }))
        deleteAccountManager(accountManager)
    }
}

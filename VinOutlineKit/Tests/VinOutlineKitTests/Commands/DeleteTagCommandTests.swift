import Foundation
import Testing
@testable import VinOutlineKit

final class DeleteTagCommandTests: VOKTestCase {
	
    @Test("DeleteTagCommand deletes a tag and is undoable")
    func deleteTagAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let tagName = "TestTag"
		let tag = Tag(name: tagName)
		outline.account?.createTag(tag)
		outline.createTag(tag)
		
		let command = DeleteTagCommand(actionName: "DeleteTag", undoManager: undoManager, delegate: self, outline: outline, tagName: tagName)
        command.execute()
        #expect(!outline.tags.contains(where: { $0.name == tagName }))
		
        undoManager.undo()
        #expect(outline.tags.contains(where: { $0.name == tagName }))
		
        undoManager.redo()
        #expect(!outline.tags.contains(where: { $0.name == tagName }))
		
        deleteAccountManager(accountManager)
    }
}

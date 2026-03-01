import Foundation
import Testing
@testable import VinOutlineKit

final class CreateRowAfterCommandTests: VOKTestCase {
	
    @Test("CreateRowAfterCommand creates row after with indent and is undoable")
    func createAfterAndUndoWithIndent() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)

        let afterRow = try #require(outline.rows.first)
		let command = CreateRowAfterCommand(actionName: "CreateAfter",
											undoManager: undoManager,
											delegate: self,
											outline: outline,
											afterRow: afterRow,
											rowStrings: nil,
											childRowIndent: true)
		let originalCount = outline.rows.first?.rows.count ?? 0
        command.execute()
        #expect(outline.rows.first?.rows.count ?? 0 == originalCount + 1)

        undoManager.undo()
        #expect(outline.rows.first?.rows.count ?? 0 == originalCount)
        deleteAccountManager(accountManager)
    }
	
	@Test("CreateRowAfterCommand creates row after without indent and is undoable")
	func createAfterAndUndoWithoutIndent() async throws {
		let accountManager = buildAccountManager()
		let undoManager = UndoManager()
		let outline = try await loadOutline(accountManager: accountManager)

		let afterRow = try #require(outline.rows.first)
		let command = CreateRowAfterCommand(actionName: "CreateAfter",
											undoManager: undoManager,
											delegate: self,
											outline: outline,
											afterRow: afterRow,
											rowStrings: nil,
											childRowIndent: false)
		let originalCount = outline.rows.count
		command.execute()
		#expect(outline.rows.count == originalCount + 1)

		undoManager.undo()
		#expect(outline.rows.count == originalCount)
		deleteAccountManager(accountManager)
	}

}

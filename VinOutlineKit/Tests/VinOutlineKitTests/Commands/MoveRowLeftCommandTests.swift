//
//  MoveRowLeftCommandTests.swift
//  VinOutlineKit
//
//  Created by Maurice Parker on 7/2/25.
//


import Foundation
import Testing
@testable import VinOutlineKit

final class MoveRowLeftCommandTests: VOKTestCase {
	
    @Test("MoveRowLeftCommand moves row left and is undoable")
    func moveLeftAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
		let row = try #require(outline.rows.first?.rows.first)
        // Move right first to guarantee we can move left
        let _ = outline.moveRowsRight([row], rowStrings: nil)
        let command = MoveRowLeftCommand(actionName: "MoveLeft", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: nil)
        command.execute()
        #expect(row.trueLevel == 0)
        undoManager.undo()
        #expect(row.trueLevel > 0)
        deleteAccountManager(accountManager)
    }

	@Test("Return outdents an emptied last child, even though its saved topic still has text")
	func shouldMoveLeftOnReturnWithEmptiedTopic() async throws {
		let before = """
			- Alpha
			  - A1
			  - x
			- Bravo
			"""
		let (outline, accountManager) = try await makeOutline(before)
		defer { deleteAccountManager(accountManager) }

		let row = try outline.row(titled: "x")

		// The editor hasn't saved the deletion yet, so the row still has "x" but the text view is empty.
		let emptyTopic = NSAttributedString()
		#expect(outline.shouldMoveLeftOnReturn(row: row, topic: emptyTopic))
		#expect(outline.shouldMoveLeftOnReturn(row: row, topic: nil))
		#expect(!outline.shouldMoveLeftOnReturn(row: row, topic: NSAttributedString(string: "x")))

		let command = MoveRowLeftCommand(actionName: "MoveLeft", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: .topic(emptyTopic))
		command.execute()

		expectEdit(outline, before: before, after: """
			- Alpha
			  - A1
			-
			- Bravo
			""")
	}

	@Test("Return doesn't outdent an empty row that isn't the last child or is at the top level")
	func shouldNotMoveLeftOnReturn() async throws {
		let (outline, accountManager) = try await makeOutline("""
			- Alpha
			  - A1
			  - A2
			- Bravo
			""")
		defer { deleteAccountManager(accountManager) }

		#expect(!outline.shouldMoveLeftOnReturn(row: try outline.row(titled: "A1"), topic: nil))
		#expect(!outline.shouldMoveLeftOnReturn(row: try outline.row(titled: "Bravo"), topic: nil))
	}

}

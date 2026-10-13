import Foundation
import Testing
@testable import VinOutlineKit

final class MoveRowRightCommandTests: VOKTestCase {
	
    @Test("MoveRowRightCommand moves a row right and is undoable")
    func moveRowRightAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.last)
        let moveRightRow = Row(outline: outline)
        outline.createRow(moveRightRow, afterRow: row, rowStrings: nil)
        let command = MoveRowRightCommand(actionName: "MoveRight", undoManager: undoManager, delegate: self, outline: outline, rows: [moveRightRow], rowStrings: nil)
        
		command.execute()
        #expect(moveRightRow.parent === row)
		#expect(moveRightRow.trueLevel > 0)

		undoManager.undo()
        #expect(moveRightRow.parent === outline)
		#expect(moveRightRow.trueLevel == 0)
        
		undoManager.redo()
        #expect(moveRightRow.parent === row)
		#expect(moveRightRow.trueLevel > 0)
		
        deleteAccountManager(accountManager)
    }

	@Test("Undoing MoveRowRightCommand restores a parent that was auto uncompleted")
	func undoRestoresAutoUncompletedParent() async throws {
		let accountManager = buildAccountManager()
		let undoManager = UndoManager()
		let outline = try await loadOutline(accountManager: accountManager)
		let parent = try #require(outline.rows.last)
		parent.isComplete = true
		let moveRightRow = Row(outline: outline)
		outline.createRow(moveRightRow, afterRow: parent, rowStrings: nil)
		let command = MoveRowRightCommand(actionName: "MoveRight", undoManager: undoManager, delegate: self, outline: outline, rows: [moveRightRow], rowStrings: nil)

		command.execute()
		#expect(moveRightRow.parent === parent)
		#expect(parent.isComplete == false)

		undoManager.undo()
		#expect(moveRightRow.parent === outline)
		#expect(parent.isComplete == true)

		undoManager.redo()
		#expect(moveRightRow.parent === parent)
		#expect(parent.isComplete == false)

		deleteAccountManager(accountManager)
	}

	@Test("Undoing MoveRowRightCommand restores a parent that was auto completed")
	func undoRestoresAutoCompletedParent() async throws {
		let accountManager = buildAccountManager()
		let undoManager = UndoManager()
		let outline = try await loadOutline(accountManager: accountManager)
		let parent = try #require(outline.rows.last)
		parent.isComplete = false
		let child = Row(outline: outline)
		child.isComplete = true
		parent.appendRow(child)
		child.parent = parent
		let moveRightRow = Row(outline: outline)
		moveRightRow.isComplete = true
		outline.createRow(moveRightRow, parent: outline, index: outline.rows.count, rowStrings: nil)
		moveRightRow.parent = outline
		#expect(outline.rows.last === moveRightRow)
		let command = MoveRowRightCommand(actionName: "MoveRight", undoManager: undoManager, delegate: self, outline: outline, rows: [moveRightRow], rowStrings: nil)

		command.execute()
		#expect(moveRightRow.parent === parent)
		#expect(parent.isComplete == true)

		undoManager.undo()
		#expect(moveRightRow.parent === outline)
		#expect(parent.isComplete == false)

		undoManager.redo()
		#expect(moveRightRow.parent === parent)
		#expect(parent.isComplete == true)

		deleteAccountManager(accountManager)
	}

}

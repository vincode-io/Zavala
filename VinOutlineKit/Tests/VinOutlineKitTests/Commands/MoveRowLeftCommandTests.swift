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
	
}

//
//  ExpandCommandTests.swift
//  VinOutlineKit
//
//  Created by Maurice Parker on 7/2/25.
//


import Foundation
import Testing
@testable import VinOutlineKit

final class ExpandCommandTests: VOKTestCase {
	
    @Test("ExpandCommand expands rows and is undoable")
    func expandAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        outline.collapse(rows: [row])
        let command = ExpandCommand(actionName: "Expand", undoManager: undoManager, delegate: self, outline: outline, rows: [row])
        command.execute()
        #expect(row.isExpanded == true)
        undoManager.undo()
        #expect(row.isExpanded == false)
        deleteAccountManager(accountManager)
    }
	
}

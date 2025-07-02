//
//  CollapseCommandTests.swift
//  VinOutlineKit
//
//  Created by Maurice Parker on 7/2/25.
//


import Foundation
import Testing
@testable import VinOutlineKit

final class CollapseCommandTests: VOKTestCase {
	
    @Test("CollapseCommand collapses rows and is undoable")
    func collapseAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let row = try #require(outline.rows.first)
        outline.expand(rows: [row])
        let command = CollapseCommand(actionName: "Collapse", undoManager: undoManager, delegate: self, outline: outline, rows: [row])
        command.execute()
        #expect(row.isExpanded == false)
        undoManager.undo()
        #expect(row.isExpanded == true)
        deleteAccountManager(accountManager)
    }
	
}

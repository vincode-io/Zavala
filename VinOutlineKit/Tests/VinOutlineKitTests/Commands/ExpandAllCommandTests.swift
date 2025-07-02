//
//  ExpandAllCommandTests.swift
//  VinOutlineKit
//
//  Created by Maurice Parker on 7/2/25.
//


import Foundation
import Testing
@testable import VinOutlineKit

final class ExpandAllCommandTests: VOKTestCase {
	
    @Test("ExpandAllCommand expands all containers and is undoable")
    func expandAllAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let command = ExpandAllCommand(actionName: "ExpandAll", undoManager: undoManager, delegate: self, outline: outline, containers: [outline])
        let _ = outline.collapseAll(containers: [outline])
        command.execute()
		#expect(outline.rows.allSatisfy { $0.rowCount == 0 || $0.isExpanded })
        undoManager.undo()
		#expect(outline.rows.allSatisfy { $0.rowCount == 0 || !$0.isExpanded })
        deleteAccountManager(accountManager)
    }
	
}

//
//  CollapseAllCommandTests.swift
//  VinOutlineKit
//
//  Created by Maurice Parker on 7/2/25.
//


import Foundation
import Testing
@testable import VinOutlineKit

final class CollapseAllCommandTests: VOKTestCase {
	
    @Test("CollapseAllCommand collapses all containers and is undoable")
    func collapseAllAndUndo() async throws {
        let accountManager = buildAccountManager()
        let undoManager = UndoManager()
        let outline = try await loadOutline(accountManager: accountManager)
        let command = CollapseAllCommand(actionName: "CollapseAll", undoManager: undoManager, delegate: self, outline: outline, containers: [outline])
        let _ = outline.expandAll(containers: [outline])
		
        command.execute()
		#expect(outline.rows.allSatisfy { $0.rowCount == 0 || !$0.isExpanded })
		
        undoManager.undo()
        #expect(outline.rows.allSatisfy { $0.rowCount == 0 || $0.isExpanded })
		
        undoManager.redo()
        #expect(outline.rows.allSatisfy { $0.rowCount == 0 || !$0.isExpanded })
		
        deleteAccountManager(accountManager)
    }
	
}


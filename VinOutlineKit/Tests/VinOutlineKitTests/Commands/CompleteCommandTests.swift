//
//  CompleteCommandTests.swift
//  
//
//  Created by Maurice Parker on 3/21/24.
//

import Foundation
import Testing
@testable import VinOutlineKit

final class CompleteCommandTests: VOKTestCase {

	@Test func execute() async throws {
		let accountManager = buildAccountManager()
		let undoManager = UndoManager()
		
		let outline = try await loadOutline(accountManager: accountManager)
		let row = try #require(outline.rows.first)
		let rowStrings = RowStrings.topic(NSAttributedString(string: "Test 1 - Changed"))
		
		let command = CompleteCommand(actionName: "Complete", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: rowStrings)
		command.execute()

		#expect(outline.rows.first!.isComplete!)
		#expect(outline.rows.first!.topic!.string == "Test 1 - Changed")
		
		undoManager.undo()
		
		#expect(outline.rows.first!.isComplete! == false)
		#expect(outline.rows.first!.topic!.string == "Test 1")
	}

}

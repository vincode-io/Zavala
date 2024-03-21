//
//  CompleteCommandTests.swift
//  
//
//  Created by Maurice Parker on 3/21/24.
//

import XCTest
@testable import VinOutlineKit

final class CompleteCommandTests: VOKTestCase {

	func testExecute() throws {
		let outline = try loadOutline()
		
		guard let row = outline.rows.first else {
			XCTFail()
			return
		}
		
		let rowStrings = RowStrings.topic(NSAttributedString(string: "Test 1 - Changed"))
		
		let command = CompleteCommand(actionName: "Complete", undoManager: undoManager, delegate: self, outline: outline, rows: [row], rowStrings: rowStrings)
		command.execute()
		
		XCTAssertTrue(outline.rows.first!.isComplete!)
		XCTAssertEqual(outline.rows.first!.topic!.string, "Test 1 - Changed")
		undoManager.undo()
		XCTAssertFalse(outline.rows.first!.isComplete!)
		XCTAssertEqual(outline.rows.first!.topic!.string, "Test 1")
	}

}

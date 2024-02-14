//
//  CreateRowBeforeCommand.swift
//
//  Created by Maurice Parker on 12/15/20.
//

import Foundation

public final class CreateRowBeforeCommand: OutlineCommand {

	var row: Row
	var beforeRow: Row
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, beforeRow: Row) {
		self.row = Row(outline: outline)
		self.beforeRow = beforeRow

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		outline.createRow(row, beforeRow: beforeRow)
	}
	
	public override func undo() {
		outline.deleteRows([row])
	}
	
}

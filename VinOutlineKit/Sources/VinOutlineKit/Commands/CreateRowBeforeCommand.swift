//
//  CreateRowBeforeCommand.swift
//
//  Created by Maurice Parker on 12/15/20.
//

import Foundation

public final class CreateRowBeforeCommand: OutlineCommand {

	var row: Row
	var beforeRow: Row
	var rowStrings: RowStrings?
	var moveCursor: Bool
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, beforeRow: Row, rowStrings: RowStrings?, moveCursor: Bool) {
		self.row = Row(outline: outline)
		self.beforeRow = beforeRow
		self.rowStrings = rowStrings
		self.moveCursor = moveCursor

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		outline.createRow(row, beforeRow: beforeRow, rowStrings: rowStrings, moveCursor: moveCursor)
	}
	
	public override func undo() {
		outline.deleteRows([row])
	}
	
}

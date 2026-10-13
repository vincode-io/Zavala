//
//  CompleteCommand.swift
//  
//
//  Created by Maurice Parker on 12/28/20.
//

import Foundation

public final class CompleteCommand: OutlineCommand {
	
	var rows: [Row]

	// Only the rows that weren't already complete, so that undo doesn't uncomplete rows that started out complete
	var changedRows: [Row]

	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?

	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.rows = rows
		self.changedRows = rows.filter { !($0.isComplete ?? false) }

		if rows.count == 1, let row = rows.first {
			self.oldRowStrings = row.rowStrings
			self.newRowStrings = rowStrings
		}

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	override public func perform() {
		outline.complete(rows: rows, rowStrings: newRowStrings)
	}
	
	override public func undo() {
		outline.uncomplete(rows: changedRows, rowStrings: oldRowStrings)
	}
	
}

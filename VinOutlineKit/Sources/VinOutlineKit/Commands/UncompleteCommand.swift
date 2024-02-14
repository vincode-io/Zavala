//
//  UncompleteCommand.swift
//  
//
//  Created by Maurice Parker on 12/28/20.
//

import Foundation

public final class UncompleteCommand: OutlineCommand {
	
	var rows: [Row]
	var completedRows: [Row]?
	
	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?

	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.rows = rows
		
		if rows.count == 1, let row = rows.first {
			self.oldRowStrings = row.rowStrings
			self.newRowStrings = rowStrings
		}

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		completedRows = outline.uncomplete(rows: rows, rowStrings: newRowStrings)
	}
	
	public override func undo() {
		guard let completedRows else { return }
		outline.complete(rows: completedRows, rowStrings: oldRowStrings)
	}
	
}

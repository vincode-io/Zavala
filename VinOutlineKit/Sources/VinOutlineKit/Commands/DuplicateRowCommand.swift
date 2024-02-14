//
//  DuplicateRowCommand.swift
//
//
//  Created by Maurice Parker on 8/7/21.
//

import Foundation

public final class DuplicateRowCommand: OutlineCommand {
	
	var rows: [Row]
	var newRows: [Row]?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row]) {
		self.rows = rows

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		if let newRows {
			outline.createRows(newRows, afterRow: rows.sortedByDisplayOrder().first)
		} else {
			newRows = outline.duplicateRows(rows)
		}
	}
	
	public override func undo() {
		guard let newRows else {
			return
		}
		outline.deleteRows(newRows)
	}
	
}

//
//  DeleteRowCommand.swift
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation

public final class DeleteRowCommand: OutlineCommand {

	var rows: [Row]
	var currentRow: Row?
	var rowStrings: RowStrings?
	var locations = [(row: Row, parent: RowContainer, index: Int)]()
	var isInOutlineMode: Bool

	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], currentRow: Row?, rowStrings: RowStrings?, isInOutlineMode: Bool) {
		self.locations = outline.rowLocations(for: rows)
		self.rows = locations.map { $0.row }

		self.currentRow = currentRow
		self.rowStrings = rowStrings
		self.isInOutlineMode = isInOutlineMode

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		outline.deleteRows(rows, currentRow: currentRow, rowStrings: rowStrings, isInOutlineMode: isInOutlineMode)
	}
	
	public override func undo() {
		outline.restoreRows(locations)
	}
	
}

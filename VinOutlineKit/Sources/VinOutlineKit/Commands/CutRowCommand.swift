//
//  CutRowCommand.swift
//
//
//  Created by Maurice Parker on 12/31/20.
//

import Foundation

public final class CutRowCommand: OutlineCommand {

	var rows: [Row]
	var locations = [(row: Row, parent: RowContainer, index: Int)]()
	var isInOutlineMode: Bool
	var oldCompletionStates = [(row: Row, isComplete: Bool?)]()

	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], isInOutlineMode: Bool) {
		self.rows = rows
		self.locations = outline.rowLocations(for: rows)
		self.rows = locations.map { $0.row }
		self.oldCompletionStates = outline.completionStates(forRowsAndAncestorsOf: self.rows)
		self.isInOutlineMode = isInOutlineMode

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}

	public override func perform() {
		outline.deleteRows(rows, isInOutlineMode: isInOutlineMode)
	}

	public override func undo() {
		outline.restoreRows(locations)
		outline.restoreCompletionStates(oldCompletionStates)
	}

}

//
//  MoveRowRightCommand.swift
//  
//
//  Created by Maurice Parker on 6/29/21.
//

import Foundation

public final class MoveRowRightCommand: OutlineCommand {
	
	var rows: [Row]
	var moveRightRows: [Row]?
	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?
	var oldCompletionStates = [(row: Row, isComplete: Bool?)]()
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.rows = rows
		
		if rows.count == 1, let row = rows.first {
			self.oldRowStrings = row.rowStrings
			self.newRowStrings = rowStrings
		}

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		saveCompletionStates()
		moveRightRows = outline.moveRowsRight(rows, rowStrings: newRowStrings)
	}
	
	public override func undo() {
		guard let moveRightRows else { return }
		outline.moveRowsLeft(moveRightRows, rowStrings: oldRowStrings)
		restoreCompletionStates()
	}
	
}

private extension MoveRowRightCommand {

	/// Moving a row right can auto complete or uncomplete the new parent row, which cascades up
	/// through its ancestors. Save the completion state of every row that could be affected so that
	/// undo can restore it instead of recalculating it.
	func saveCompletionStates() {
		var savedRows = Set<Row>()
		oldCompletionStates.removeAll()

		for row in rows {
			guard let container = row.parent,
				  let rowIndex = container.firstIndexOfRow(row),
				  rowIndex > 0 else { continue }

			var affectedRow: Row? = container.rows[rowIndex - 1]
			while let currentRow = affectedRow {
				if !savedRows.contains(currentRow) {
					savedRows.insert(currentRow)
					oldCompletionStates.append((row: currentRow, isComplete: currentRow.isComplete))
				}
				affectedRow = currentRow.parent as? Row
			}
		}
	}

	/// Restore the deepest rows first so that any cascading auto complete changes are overwritten by
	/// the saved state of their ancestors.
	func restoreCompletionStates() {
		let sortedStates = oldCompletionStates.sorted { $0.row.trueLevel > $1.row.trueLevel }

		for (row, isComplete) in sortedStates {
			let wasComplete = isComplete ?? false
			guard wasComplete != (row.isComplete ?? false) else { continue }

			if wasComplete {
				outline.complete(rows: [row])
			} else {
				outline.uncomplete(rows: [row])
			}
		}
	}

}

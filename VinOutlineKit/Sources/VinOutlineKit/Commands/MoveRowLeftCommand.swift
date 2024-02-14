//
//  MoveRowLeftCommand.swift
//  
//
//  Created by Maurice Parker on 6/29/21.
//

import Foundation

public final class MoveRowLeftCommand: OutlineCommand {
	
	var rows: [Row]
	var restoreMoves = [Outline.RowMove]()
	var moveLeftRows: [Row]?

	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.rows = rows
		
		for row in rows {
			guard let oldParent = row.parent, let oldChildIndex = oldParent.firstIndexOfRow(row) else { continue }
			restoreMoves.append(Outline.RowMove(row: row, toParent: oldParent, toChildIndex: oldChildIndex))
		}
		
		if rows.count == 1, let row = rows.first {
			self.oldRowStrings = row.rowStrings
			self.newRowStrings = rowStrings
		}

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		saveCursorCoordinates()
		moveLeftRows = outline.moveRowsLeft(rows, rowStrings: newRowStrings)
		registerUndo()
	}
	
	public override func undo() {
		guard let moveLeftRows else { return }
		let movedLeft = Set(moveLeftRows)
		let moveLeftRestore = restoreMoves.filter { movedLeft.contains($0.row) }
		outline.moveRows(moveLeftRestore, rowStrings: oldRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

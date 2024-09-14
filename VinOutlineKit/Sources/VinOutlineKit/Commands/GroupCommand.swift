//
//  Created by Maurice Parker on 9/14/24.
//

import Foundation

public final class GroupCommand: OutlineCommand {
	
	var newRow: Row
	var rows: [Row]
	var moveRightRows: [Row]?
	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.newRow = Row(outline: outline)
		self.rows = rows
		
		if rows.count == 1, let row = rows.first {
			self.oldRowStrings = row.rowStrings
			self.newRowStrings = rowStrings
		}

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		guard let firstRow = rows.first else { return }
		outline.createRow(newRow, beforeRow: firstRow, moveCursor: true)
		moveRightRows = outline.moveRowsRight(rows, rowStrings: newRowStrings)
	}
	
	public override func undo() {
		guard let moveRightRows else { return }
		outline.moveRowsLeft(moveRightRows, rowStrings: oldRowStrings)
		outline.deleteRows([newRow])
	}
	
}

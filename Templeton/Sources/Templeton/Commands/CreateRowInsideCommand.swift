//
//  CreateRowInsideCommand.swift
//  
//
//  Created by Maurice Parker on 6/30/21.
//

import Foundation
import RSCore

public final class CreateRowInsideCommand: OutlineCommand {
	public var newCursorIndex: Int?

	var row: Row?
	var afterRow: Row
	var rowStrings: RowStrings?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, afterRow: Row, rowStrings: RowStrings?) {
		self.afterRow = afterRow
		self.rowStrings = rowStrings

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		saveCursorCoordinates()
		if row == nil {
			row = Row(outline: outline)
		}
		newCursorIndex = outline.createRowsInsideAtStart([row!], afterRowContainer: afterRow, rowStrings: rowStrings)
		registerUndo()
	}
	
	public override func undo() {
		guard let row else { return }
		outline.deleteRows([row])
		registerRedo()
		restoreCursorPosition()
	}
	
}

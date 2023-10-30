//
//  DeleteNoteCommand.swift
//
//  Created by Maurice Parker on 12/13/20.
//

import Foundation

public final class DeleteNoteCommand: OutlineCommand {
	public var newCursorIndex: Int?

	var rows: [Row]
	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?
	var deletedRowNotes: [Row: NSAttributedString]?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.rows = rows
		
		if rows.count == 1, let row = rows.first {
			self.oldRowStrings = row.rowStrings
			self.newRowStrings = rowStrings
		}

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		saveCursorCoordinates()
		let (impacted, newCursorIndex) = outline.deleteNotes(rows: rows, rowStrings: newRowStrings)
		deletedRowNotes = impacted
		self.newCursorIndex = newCursorIndex
		registerUndo()
	}
	
	public override func undo() {
		outline.restoreNotes(deletedRowNotes ?? [Row: NSAttributedString]())
		registerRedo()
		restoreCursorPosition()
	}
	
}

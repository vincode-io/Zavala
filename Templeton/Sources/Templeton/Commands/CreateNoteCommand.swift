//
//  CreateNoteCommand.swift
//
//  Created by Maurice Parker on 12/13/20.
//

import Foundation
import RSCore

public final class CreateNoteCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	public weak var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var newCursorIndex: Int?

	public var outline: Outline
	var rows: [Row]
	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?
	
	var noteCreatedRows: [Row]?

	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		undoActionName = L10n.addNote
		redoActionName = L10n.addNote

		if rows.count == 1, let row = rows.first {
			self.oldRowStrings = row.rowStrings
			self.newRowStrings = rowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		let (impacted, newCursorIndex) = outline.createNotes(rows: rows, rowStrings: newRowStrings)
		noteCreatedRows = impacted
		self.newCursorIndex = newCursorIndex
		registerUndo()
	}
	
	public func undo() {
		outline.deleteNotes(rows: noteCreatedRows ?? [Row](), rowStrings: oldRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

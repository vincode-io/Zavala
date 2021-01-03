//
//  DeleteNoteCommand.swift
//
//  Created by Maurice Parker on 12/13/20.
//

import Foundation
import RSCore

public final class DeleteNoteCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var newCursorIndex: Int?

	var outline: Outline
	var rows: [Row]
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings?
	var deletedRowNotes: [Row: NSAttributedString]?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.deleteNote
		self.redoActionName = L10n.deleteNote
		
		if rows.count == 1, let textRow = rows.first?.textRow {
			self.oldTextRowStrings = textRow.textRowStrings
			self.newTextRowStrings = textRowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		let (impacted, newCursorIndex) = outline.deleteNotes(rows: rows, textRowStrings: newTextRowStrings)
		deletedRowNotes = impacted
		self.newCursorIndex = newCursorIndex
		registerUndo()
	}
	
	public func undo() {
		outline.restoreNotes(deletedRowNotes ?? [Row: NSAttributedString]())
		registerRedo()
		restoreCursorPosition()
	}
	
}

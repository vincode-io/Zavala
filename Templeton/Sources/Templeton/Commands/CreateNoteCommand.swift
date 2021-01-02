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
	
	public var changes: ShadowTableChanges?

	var outline: Outline
	var rows: [Row]
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings?
	
	var noteCreatedRows: [Row]?

	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		undoActionName = L10n.addNote
		redoActionName = L10n.addNote

		if rows.count == 1, let textRow = rows.first?.textRow {
			self.oldTextRowStrings = textRow.textRowStrings
			self.newTextRowStrings = textRowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		let (impacted, changes) = outline.createNotes(rows: rows, textRowStrings: newTextRowStrings)
		noteCreatedRows = impacted
		self.changes = changes
		registerUndo()
	}
	
	public func undo() {
		outline.deleteNotes(rows: noteCreatedRows ?? [Row](), textRowStrings: oldTextRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

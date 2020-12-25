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
	
	public var changes: ShadowTableChanges?

	var outline: Outline
	var row: Row
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, row: Row, textRowStrings: TextRowStrings) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.oldTextRowStrings = row.textRow?.textRowStrings
		self.newTextRowStrings = textRowStrings
		undoActionName = L10n.deleteNote
		redoActionName = L10n.deleteNote
	}
	
	public func perform() {
		saveCursorCoordinates()
		changes = outline.deleteNote(row: row, textRowStrings: newTextRowStrings)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	public func undo() {
		let changes = outline.createNote(row: row, textRowStrings: oldTextRowStrings)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

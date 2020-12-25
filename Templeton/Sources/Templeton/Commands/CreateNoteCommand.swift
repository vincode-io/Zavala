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
		undoActionName = L10n.addNote
		redoActionName = L10n.addNote
	}
	
	public func perform() {
		saveCursorCoordinates()
		changes = outline.createNote(row: row, textRowStrings: newTextRowStrings)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	public func undo() {
		let changes = outline.deleteNote(row: row, textRowStrings: oldTextRowStrings)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

//
//  EditorTextChangedCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorTextChangedCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var row: Row
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings
	var applyChanges = false
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, row: Row, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.undoActionName = L10n.typing
		self.redoActionName = L10n.typing

		oldTextRowStrings = row.textRow?.textRowStrings
		newTextRowStrings = textRowStrings
		
		cursorCoordinates = CursorCoordinates(row: row, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func perform() {
		let changes = outline.updateRow(row, textRowStrings: newTextRowStrings)
		if applyChanges {
			delegate?.applyChangesRestoringCursor(changes)
		}
		applyChanges = true
		registerUndo()
	}
	
	func undo() {
		let changes = outline.updateRow(row, textRowStrings: oldTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

//
//  EditorToggleCompleteRowCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 11/30/20.
//

import Foundation
import RSCore
import Templeton

final class EditorToggleCompleteRowCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var row: TextRow
	var oldTextRowStrings: TextRowStrings
	var newTextRowStrings: TextRowStrings
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, row: TextRow, textRowStrings: TextRowStrings) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.undoActionName = L10n.complete
		self.redoActionName = L10n.complete
		
		oldTextRowStrings = row.textRowStrings
		newTextRowStrings = textRowStrings
	}
	
	func perform() {
		saveCursorCoordinates()
		changes = outline.toggleComplete(row: row, textRowStrings: newTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes!)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.toggleComplete(row: row, textRowStrings: oldTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

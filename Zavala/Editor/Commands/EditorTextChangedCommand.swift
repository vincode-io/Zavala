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
	var headline: TextRow
	var oldTextRowStrings: TextRowStrings
	var newTextRowStrings: TextRowStrings
	var applyChanges = false
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: TextRow, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.undoActionName = L10n.typing
		self.redoActionName = L10n.typing

		oldTextRowStrings = headline.textRowStrings
		newTextRowStrings = textRowStrings
		
		cursorCoordinates = CursorCoordinates(row: headline, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func perform() {
		let changes = outline.updateHeadline(headline: headline, textRowStrings: newTextRowStrings)
		if applyChanges {
			delegate?.applyChangesRestoringCursor(changes)
		}
		applyChanges = true
		registerUndo()
	}
	
	func undo() {
		let changes = outline.updateHeadline(headline: headline, textRowStrings: oldTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

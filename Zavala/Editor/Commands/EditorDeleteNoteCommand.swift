//
//  EditorDeleteNoteCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 12/13/20.
//

import Foundation
import RSCore
import Templeton

final class EditorDeleteNoteCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var headline: TextRow
	var oldTextRowStrings: TextRowStrings
	var newTextRowStrings: TextRowStrings
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: TextRow, textRowStrings: TextRowStrings) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.oldTextRowStrings = headline.textRowStrings
		self.newTextRowStrings = textRowStrings
		undoActionName = L10n.deleteNote
		redoActionName = L10n.deleteNote
	}
	
	func perform() {
		saveCursorCoordinates()
		changes = outline.deleteNote(headline: headline, textRowStrings: newTextRowStrings)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.createNote(headline: headline, textRowStrings: oldTextRowStrings)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

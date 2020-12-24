//
//  EditorIndentHeadlineCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorIndentHeadlineCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var headline: TextRow
	var oldTextRowStrings: TextRowStrings
	var newTextRowStrings: TextRowStrings
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: TextRow, textRowStrings: TextRowStrings) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.undoActionName = L10n.indent
		self.redoActionName = L10n.indent
		
		oldTextRowStrings = headline.textRowStrings
		newTextRowStrings = textRowStrings
	}
	
	func perform() {
		saveCursorCoordinates()
		let changes = outline.indentHeadline(headline: headline, textRowStrings: newTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.outdentHeadline(headline: headline, textRowStrings: oldTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

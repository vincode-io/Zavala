//
//  EditorCreateHeadlineCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorCreateHeadlineAfterCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var headline: TextRow?
	var afterHeadline: TextRow?
	var textRowStrings: TextRowStrings?
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, afterHeadline: TextRow?, textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.afterHeadline = afterHeadline
		self.textRowStrings = textRowStrings
		undoActionName = L10n.addRow
		redoActionName = L10n.addRow
	}
	
	func perform() {
		saveCursorCoordinates()
		if headline == nil {
			headline = TextRow()
		}
		changes = outline.createRow(headline!, afterRow: afterHeadline, textRowStrings: textRowStrings)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		guard let headline = headline else { return }
		let changes = outline.deleteRow(headline)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

//
//  EditorOutdentHeadlineCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorOutdentHeadlineCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var headline: TextRow
	var oldParent: TextRow?
	var oldChildIndex: Int?
	var oldTextRowStrings: TextRowStrings
	var newTextRowStrings: TextRowStrings
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: TextRow, textRowStrings: TextRowStrings) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.undoActionName = L10n.outdent
		self.redoActionName = L10n.outdent
		
		// This is going to move, so we save the parent and child index
		if headline != headline.parent?.rows?.last {
			self.oldParent = headline.parent as? TextRow
			self.oldChildIndex = headline.parent?.rows?.firstIndex(of: headline)
		}
		
		self.oldTextRowStrings = headline.textRowStrings
		self.newTextRowStrings = textRowStrings
	}
	
	func perform() {
		saveCursorCoordinates()
		let changes = outline.outdentRow(headline, textRowStrings: newTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	func undo() {
		if let oldParent = oldParent, let oldChildIndex = oldChildIndex {
			let changes = outline.moveRow(headline, textRowStrings: oldTextRowStrings, toParent: oldParent, childIndex: oldChildIndex)
			delegate?.applyChangesRestoringCursor(changes)
		} else {
			let changes = outline.indentRow(headline, textRowStrings: oldTextRowStrings)
			delegate?.applyChangesRestoringCursor(changes)
		}
		registerRedo()
		restoreCursorPosition()
	}
	
}

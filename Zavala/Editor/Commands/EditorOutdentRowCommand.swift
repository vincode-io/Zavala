//
//  EditorOutdentRowCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorOutdentRowCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var row: Row
	var oldParent: Row?
	var oldChildIndex: Int?
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, row: Row, textRowStrings: TextRowStrings) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.undoActionName = L10n.outdent
		self.redoActionName = L10n.outdent
		
		// This is going to move, so we save the parent and child index
		if row != row.parent?.rows?.last {
			self.oldParent = row.parent as? Row
			self.oldChildIndex = row.parent?.rows?.firstIndex(of: row)
		}
		
		self.oldTextRowStrings = row.textRow?.textRowStrings
		self.newTextRowStrings = textRowStrings
	}
	
	func perform() {
		saveCursorCoordinates()
		let changes = outline.outdentRow(row, textRowStrings: newTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	func undo() {
		if let oldParent = oldParent, let oldChildIndex = oldChildIndex {
			let changes = outline.moveRow(row, textRowStrings: oldTextRowStrings, toParent: oldParent, childIndex: oldChildIndex)
			delegate?.applyChangesRestoringCursor(changes)
		} else {
			let changes = outline.indentRow(row, textRowStrings: oldTextRowStrings)
			delegate?.applyChangesRestoringCursor(changes)
		}
		registerRedo()
		restoreCursorPosition()
	}
	
}

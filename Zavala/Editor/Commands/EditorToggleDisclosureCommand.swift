//
//  EditorToggleDisclosureCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 11/27/20.
//

import Foundation
import RSCore
import Templeton

final class EditorToggleDisclosureCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var row: Row
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, row: Row) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		if row.isExpanded ?? true {
			undoActionName = L10n.collapse
			redoActionName = L10n.collapse
		} else {
			undoActionName = L10n.expand
			redoActionName = L10n.expand
		}
	}
	
	func perform() {
		saveCursorCoordinates()
		let changes = outline.toggleDisclosure(row: row)
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.toggleDisclosure(row: row)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

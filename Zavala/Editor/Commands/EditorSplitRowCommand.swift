//
//  EditorSplitRowCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 12/5/20.
//

import Foundation
import RSCore
import Templeton

final class EditorSplitRowCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var newRow: Row?
	var row: Row
	var topic: NSAttributedString
	var cursorPosition: Int
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, row: Row, topic: NSAttributedString, cursorPosition: Int) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.topic = topic
		self.cursorPosition = cursorPosition
		undoActionName = L10n.splitRow
		redoActionName = L10n.splitRow
	}
	
	func perform() {
		saveCursorCoordinates()
		if newRow == nil {
			newRow = Row.text(TextRow())
		}
		changes = outline.splitRow(newRow: newRow!, row: row, topic: topic, cursorPosition: cursorPosition)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		guard let newHeadline = newRow else { return }
		let changes = outline.joinRows(topRow: row, bottomRow: newHeadline)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

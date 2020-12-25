//
//  EditorDeleteRowCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorDeleteRowCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var row: TextRow
	var textRowStrings: TextRowStrings
	var afterRows: TextRow?
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, row: TextRow, textRowStrings: TextRowStrings) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.textRowStrings = textRowStrings
		undoActionName = L10n.delete
		redoActionName = L10n.delete
	}
	
	func perform() {
		saveCursorCoordinates()
		if let rowShadowTableIndex = row.shadowTableIndex, rowShadowTableIndex > 0 {
			afterRows = outline.shadowTable?[rowShadowTableIndex - 1]
		}
		
		changes = outline.deleteRow(row, textRowStrings: textRowStrings)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.createRow(row, afterRow: afterRows)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

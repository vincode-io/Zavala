//
//  DeleteRowCommand.swift
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore

public final class DeleteRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var changes: ShadowTableChanges?

	var outline: Outline
	var row: Row
	var textRowStrings: TextRowStrings
	var afterRows: Row?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, row: Row, textRowStrings: TextRowStrings) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.textRowStrings = textRowStrings
		undoActionName = L10n.deleteRow
		redoActionName = L10n.deleteRow
	}
	
	public func perform() {
		saveCursorCoordinates()
		if let rowShadowTableIndex = row.shadowTableIndex, rowShadowTableIndex > 0 {
			afterRows = outline.shadowTable?[rowShadowTableIndex - 1]
		}
		
		changes = outline.deleteRow(row, textRowStrings: textRowStrings)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	public func undo() {
		let changes = outline.createRow(row, afterRow: afterRows)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

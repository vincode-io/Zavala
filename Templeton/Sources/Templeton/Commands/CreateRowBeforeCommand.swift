//
//  CreateRowBeforeCommand.swift
//
//  Created by Maurice Parker on 12/15/20.
//

import Foundation
import RSCore

public final class CreateRowBeforeCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var changes: ShadowTableChanges?

	var outline: Outline
	var row: Row
	var beforeRow: Row
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, beforeRow: Row) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = Row.text(TextRow())
		self.beforeRow = beforeRow
		undoActionName = L10n.addRow
		redoActionName = L10n.addRow
	}
	
	public func perform() {
		saveCursorCoordinates()
		changes = outline.createRow(row, beforeRow: beforeRow)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	public func undo() {
		let changes = outline.deleteRows([row])
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

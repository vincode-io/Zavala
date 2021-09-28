//
//  CreateRowAfterCommand.swift
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore

public final class CreateRowAfterCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	public weak var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var newCursorIndex: Int?

	public var outline: Outline
	var row: Row?
	var afterRow: Row?
	var rowStrings: RowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, afterRow: Row?, rowStrings: RowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.afterRow = afterRow
		self.rowStrings = rowStrings
		undoActionName = L10n.addRow
		redoActionName = L10n.addRow
	}
	
	public func perform() {
		saveCursorCoordinates()
		if row == nil {
			row = Row(outline: outline)
		}
		newCursorIndex = outline.createRow(row!, afterRow: afterRow, rowStrings: rowStrings)
		registerUndo()
	}
	
	public func undo() {
		guard let row = row else { return }
		outline.deleteRows([row])
		registerRedo()
		restoreCursorPosition()
	}
	
}

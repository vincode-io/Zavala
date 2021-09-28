//
//  IndentRowCommand.swift
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore

public final class IndentRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]
	var indentedRows: [Row]?
	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.indent
		self.redoActionName = L10n.indent
		
		if rows.count == 1, let row = rows.first {
			self.oldRowStrings = row.rowStrings
			self.newRowStrings = rowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		indentedRows = outline.indentRows(rows, rowStrings: newRowStrings)
		registerUndo()
	}
	
	public func undo() {
		guard let indentedRows = indentedRows else { return }
		outline.outdentRows(indentedRows, rowStrings: oldRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

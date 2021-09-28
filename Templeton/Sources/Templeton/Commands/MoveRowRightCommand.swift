//
//  MoveRowRightCommand.swift
//  
//
//  Created by Maurice Parker on 6/29/21.
//

import Foundation
import RSCore

public final class MoveRowRightCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]
	var indentedRows: [Row]?
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.moveRight
		self.redoActionName = L10n.moveRight
		
		if rows.count == 1, let row = rows.first {
			self.oldTextRowStrings = row.textRowStrings
			self.newTextRowStrings = textRowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		indentedRows = outline.indentRows(rows, textRowStrings: newTextRowStrings)
		registerUndo()
	}
	
	public func undo() {
		guard let indentedRows = indentedRows else { return }
		outline.outdentRows(indentedRows, textRowStrings: oldTextRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

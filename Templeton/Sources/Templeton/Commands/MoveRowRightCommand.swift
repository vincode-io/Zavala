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
	var moveRightRows: [Row]?
	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.moveRight
		self.redoActionName = L10n.moveRight
		
		if rows.count == 1, let row = rows.first {
			self.oldRowStrings = row.rowStrings
			self.newRowStrings = rowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		moveRightRows = outline.moveRowsRight(rows, rowStrings: newRowStrings)
		registerUndo()
	}
	
	public func undo() {
		guard let moveRightRows = moveRightRows else { return }
		outline.moveRowsLeft(moveRightRows, rowStrings: oldRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

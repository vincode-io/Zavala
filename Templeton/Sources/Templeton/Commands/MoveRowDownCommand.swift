//
//  MoveRowDownCommand.swift
//  
//
//  Created by Maurice Parker on 6/29/21.
//

import Foundation
import RSCore

public final class MoveRowDownCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]

	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.moveDown
		self.redoActionName = L10n.moveDown
		
		if rows.count == 1, let textRow = rows.first?.textRow {
			self.oldTextRowStrings = textRow.textRowStrings
			self.newTextRowStrings = textRowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		outline.moveRowsDown(rows, textRowStrings: newTextRowStrings)
		registerUndo()
	}
	
	public func undo() {
		outline.moveRowsUp(rows, textRowStrings: oldTextRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

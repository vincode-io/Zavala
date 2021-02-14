//
//  TextChangedCommand.swift
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore

public final class TextChangedCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var row: Row
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings
	var applyChanges = false
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, row: Row, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.undoActionName = L10n.typing
		self.redoActionName = L10n.typing

		oldTextRowStrings = row.textRow?.textRowStrings
		newTextRowStrings = textRowStrings
		
		cursorCoordinates = CursorCoordinates(row: row, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	public func perform() {
		outline.updateRow(row, textRowStrings: newTextRowStrings, applyChanges: applyChanges)
		applyChanges = true
		registerUndo()
	}
	
	public func undo() {
		outline.updateRow(row, textRowStrings: oldTextRowStrings, applyChanges: applyChanges)
		registerRedo()
		restoreCursorPosition()
	}
	
}

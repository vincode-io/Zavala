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
	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings
	var applyChanges = false
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, row: Row, rowStrings: RowStrings, isInNotes: Bool, selection: NSRange) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.undoActionName = L10n.typing
		self.redoActionName = L10n.typing

		oldRowStrings = row.rowStrings
		newRowStrings = rowStrings
		
		cursorCoordinates = CursorCoordinates(row: row, isInNotes: isInNotes, selection: selection)
	}
	
	public func perform() {
		outline.updateRow(row, rowStrings: newRowStrings, applyChanges: applyChanges)
		applyChanges = true
		registerUndo()
	}
	
	public func undo() {
		outline.updateRow(row, rowStrings: oldRowStrings, applyChanges: applyChanges)
		registerRedo()
		restoreCursorPosition()
	}
	
}

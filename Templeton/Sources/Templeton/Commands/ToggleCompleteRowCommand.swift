//
//  ToggleCompleteRowCommand.swift
//
//  Created by Maurice Parker on 11/30/20.
//

import Foundation
import RSCore

public final class ToggleCompleteRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var changes: ShadowTableChanges?

	var outline: Outline
	var row: Row
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, row: Row, textRowStrings: TextRowStrings) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.undoActionName = L10n.complete
		self.redoActionName = L10n.complete
		
		oldTextRowStrings = row.textRow?.textRowStrings
		newTextRowStrings = textRowStrings
	}
	
	public func perform() {
		saveCursorCoordinates()
		changes = outline.toggleComplete(row: row, textRowStrings: newTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes!)
		registerUndo()
	}
	
	public func undo() {
		let changes = outline.toggleComplete(row: row, textRowStrings: oldTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

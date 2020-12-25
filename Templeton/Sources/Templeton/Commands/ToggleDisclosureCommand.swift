//
//  ToggleDisclosureCommand.swift
//
//  Created by Maurice Parker on 11/27/20.
//

import Foundation
import RSCore

public final class ToggleDisclosureCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var row: Row
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, row: Row) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		if row.isExpanded ?? true {
			undoActionName = L10n.collapse
			redoActionName = L10n.collapse
		} else {
			undoActionName = L10n.expand
			redoActionName = L10n.expand
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		let changes = outline.toggleDisclosure(row: row)
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	public func undo() {
		let changes = outline.toggleDisclosure(row: row)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

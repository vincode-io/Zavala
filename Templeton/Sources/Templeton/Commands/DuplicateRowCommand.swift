//
//  DuplicateRowCommand.swift
//
//
//  Created by Maurice Parker on 8/7/21.
//

import Foundation
import RSCore

public final class DuplicateRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]
	var newRows: [Row]?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row]) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.duplicate
		self.redoActionName = L10n.duplicate
	}
	
	public func perform() {
		saveCursorCoordinates()
		if let newRows = newRows {
			outline.createRows(newRows, afterRow: rows.sortedByDisplayOrder().first)
		} else {
			newRows = outline.duplicateRows(rows)
		}
		registerUndo()
	}
	
	public func undo() {
		guard let newRows = newRows else {
			return
		}

		outline.deleteRows(newRows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

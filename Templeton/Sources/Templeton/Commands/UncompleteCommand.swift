//
//  UncompleteCommand.swift
//  
//
//  Created by Maurice Parker on 12/28/20.
//

import Foundation
import RSCore

public final class UncompleteCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var rows: [Row]
	var completedRows: [Row]?
	
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings?

	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.uncomplete
		self.redoActionName = L10n.uncomplete
		
		if rows.count == 1, let textRow = rows.first?.textRow {
			self.oldTextRowStrings = textRow.textRowStrings
			self.newTextRowStrings = textRowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		completedRows = outline.uncomplete(rows: rows, textRowStrings: newTextRowStrings)
		registerUndo()
	}
	
	public func undo() {
		guard let completedRows = completedRows else { return }
		outline.complete(rows: completedRows, textRowStrings: oldTextRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

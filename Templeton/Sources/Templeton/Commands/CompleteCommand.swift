//
//  CompleteCommand.swift
//  
//
//  Created by Maurice Parker on 12/28/20.
//

import Foundation
import RSCore

public final class CompleteCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]
	var completedRows: [Row]?
	
	public var newCursorIndex: Int?
	
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings?

	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.complete
		self.redoActionName = L10n.complete
		
		if rows.count == 1, let row = rows.first {
			self.oldTextRowStrings = row.textRowStrings
			self.newTextRowStrings = textRowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		let (impacted, newCursorIndex) = outline.complete(rows: rows, textRowStrings: newTextRowStrings)
		completedRows = impacted
		self.newCursorIndex = newCursorIndex
		registerUndo()
	}
	
	public func undo() {
		guard let completedRows = completedRows else { return }
		outline.uncomplete(rows: completedRows, textRowStrings: oldTextRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

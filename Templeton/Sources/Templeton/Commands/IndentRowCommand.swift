//
//  IndentRowCommand.swift
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore

public final class IndentRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var rows: [Row]
	var indentedRows: [Row]?
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.indent
		self.redoActionName = L10n.indent
		
		if rows.count == 1, let textRow = rows.first?.textRow {
			self.oldTextRowStrings = textRow.textRowStrings
			self.newTextRowStrings = textRowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		let (impacted, changes) = outline.indentRows(rows, textRowStrings: newTextRowStrings)
		indentedRows = impacted
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	public func undo() {
		guard let indentedRows = indentedRows else { return }
		let (_, changes) = outline.outdentRows(indentedRows, textRowStrings: oldTextRowStrings)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

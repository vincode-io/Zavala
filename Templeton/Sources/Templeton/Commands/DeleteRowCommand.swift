//
//  DeleteRowCommand.swift
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore

public final class DeleteRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var newCursorIndex: Int?

	var outline: Outline
	var rows: [Row]
	var textRowStrings: TextRowStrings?
	var afterRows = [Row: Row]()
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.deleteRow
		self.redoActionName = L10n.deleteRow

		for row in rows {
			if let rowShadowTableIndex = row.shadowTableIndex, rowShadowTableIndex > 0, let afterRow = outline.shadowTable?[rowShadowTableIndex - 1] {
				afterRows[row] = afterRow
			}
		}

		self.textRowStrings = textRowStrings
	}
	
	public func perform() {
		saveCursorCoordinates()
		newCursorIndex = outline.deleteRows(rows, textRowStrings: textRowStrings)
		registerUndo()
	}
	
	public func undo() {
		for row in rows.sortedByDisplayOrder() {
			outline.createRows([row], afterRow: afterRows[row])
		}
		registerRedo()
		restoreCursorPosition()
	}
	
}

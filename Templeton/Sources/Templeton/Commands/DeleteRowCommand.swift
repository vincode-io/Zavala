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
	
	public var changes: ShadowTableChanges?

	var outline: Outline
	var rows: [Row]
	var textRowStrings: TextRowStrings?
	var afterRows = [Row: Row]()
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows

		for row in rows {
			if let rowShadowTableIndex = row.shadowTableIndex, rowShadowTableIndex > 0, let afterRow = outline.shadowTable?[rowShadowTableIndex - 1] {
				afterRows[row] = afterRow
			}
		}

		self.textRowStrings = textRowStrings
		undoActionName = L10n.deleteRow
		redoActionName = L10n.deleteRow
	}
	
	public func perform() {
		saveCursorCoordinates()
		changes = outline.deleteRows(rows, textRowStrings: textRowStrings)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	public func undo() {
		for row in rows.sortedByDisplayOrder() {
			let changes = outline.createRows([row], afterRow: afterRows[row])
			delegate?.applyChanges(changes)
		}
		registerRedo()
		restoreCursorPosition()
	}
	
}

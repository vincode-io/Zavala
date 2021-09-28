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

	public var outline: Outline
	var rows: [Row]
	var rowStrings: RowStrings?
	var afterRows = [Row: Row]()
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.deleteRow
		self.redoActionName = L10n.deleteRow

		var allRows = Set<Row>()
		
		func deleteVisitor(_ visited: Row) {
			allRows.insert(visited)
			visited.rows.forEach { $0.visit(visitor: deleteVisitor) }
		}
		rows.forEach { $0.visit(visitor: deleteVisitor(_:)) }
		
		self.rows = Array(allRows)

		for row in allRows {
			if let rowShadowTableIndex = row.shadowTableIndex, rowShadowTableIndex > 0, let afterRow = outline.shadowTable?[rowShadowTableIndex - 1] {
				afterRows[row] = afterRow.ancestorSibling(row)
			}
		}

		self.rowStrings = rowStrings
	}
	
	public func perform() {
		saveCursorCoordinates()
		newCursorIndex = outline.deleteRows(rows, rowStrings: rowStrings)
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

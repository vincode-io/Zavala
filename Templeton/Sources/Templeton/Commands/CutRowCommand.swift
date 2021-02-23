//
//  CutRowCommand.swift
//  
//
//  Created by Maurice Parker on 12/31/20.
//

import Foundation
import RSCore

public final class CutRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]
	var afterRows = [Row: Row]()
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row]) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.cut
		self.redoActionName = L10n.cut

		var allRows = [Row]()
		
		func cutVisitor(_ visited: Row) {
			allRows.append(visited)
			visited.rows.forEach { $0.visit(visitor: cutVisitor) }
		}
		rows.forEach { $0.visit(visitor: cutVisitor(_:)) }
		
		self.rows = allRows
		
		for row in allRows {
			if let rowShadowTableIndex = row.shadowTableIndex, rowShadowTableIndex > 0, let afterRow = outline.shadowTable?[rowShadowTableIndex - 1] {
				afterRows[row] = afterRow
			}
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		outline.deleteRows(rows)
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

//
//  CutRowCommand.swift
//  
//
//  Created by Maurice Parker on 12/31/20.
//

import Foundation

public final class CutRowCommand: OutlineCommand {
	
	var rows: [Row]
	var afterRows = [Row: Row]()
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row]) {
		self.rows = rows

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

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		outline.deleteRows(rows)
	}
	
	public override func undo() {
		for row in rows.sortedByDisplayOrder() {
			outline.createRows([row], afterRow: afterRows[row])
		}
	}
	
}

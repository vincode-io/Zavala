//
//  PasteRowCommand.swift
//
//  Created by Maurice Parker on 12/31/20.
//

import Foundation

public final class PasteRowCommand: OutlineCommand {
	
	var rowGroups: [RowGroup]
	var rows: [Row]
	var afterRow: Row?
	var childRowIndent: Bool

	public init(actionName: String, undoManager: UndoManager,
				delegate: OutlineCommandDelegate,
				outline: Outline,
				rowGroups: [RowGroup],
				afterRow: Row?,
				childRowIndent: Bool) {

		self.rowGroups = rowGroups
		self.rows = [Row]()
		self.afterRow = afterRow
		self.childRowIndent = childRowIndent

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		var newRows = [Row]()
		for rowGroup in rowGroups {
			let newRow = rowGroup.attach(to: outline)
			newRows.append(newRow)
		}
		rows = newRows
		
		outline.createRows(rows, afterRow: afterRow, childRowIndent: childRowIndent)
	}
	
	public override func undo() {
		var allRows = [Row]()
		
		func deleteVisitor(_ visited: Row) {
			allRows.append(visited)
			visited.rows.forEach { $0.visit(visitor: deleteVisitor) }
		}
		rows.forEach { $0.visit(visitor: deleteVisitor(_:)) }
		
		outline.deleteRows(allRows)
	}
	
}

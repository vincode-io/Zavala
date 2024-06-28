//
//  RemoteDropRowCommand.swift
//
//
//  Created by Maurice Parker on 12/30/20.
//

import Foundation

public final class RemoteDropRowCommand: OutlineCommand {
	
	var rowGroups: [RowGroup]
	var rows: [Row]
	var afterRow: Row?
	var prefersEnd: Bool
	var afterRowIsNewParent: Bool
	
	public init(actionName: String, undoManager: UndoManager,
				delegate: OutlineCommandDelegate,
				outline: Outline,
				rowGroups: [RowGroup],
				afterRow: Row?,
				prefersEnd: Bool,
				afterRowIsNewParent: Bool) {
		
		self.rowGroups = rowGroups
		self.rows = [Row]()
		self.afterRow = afterRow
		self.prefersEnd = prefersEnd
		self.afterRowIsNewParent = afterRowIsNewParent
		
		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		var newRows = [Row]()
		for rowGroup in rowGroups {
			let newRow = rowGroup.attach(to: outline)
			newRows.append(newRow)
		}
		rows = newRows
		
		// This helps Outline understand that this is a drop-into
		if afterRowIsNewParent {
			for row in rows {
				row.parent = afterRow
			}
		}
		
		outline.createRows(rows, afterRow: afterRow, prefersEnd: prefersEnd)
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

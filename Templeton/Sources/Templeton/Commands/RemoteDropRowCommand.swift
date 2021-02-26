//
//  RemoteDropRowCommand.swift
//  
//
//  Created by Maurice Parker on 12/30/20.
//

import Foundation
import RSCore

public final class RemoteDropRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rowGroups: [RowGroup]
	var rows: [Row]
	var afterRow: Row?
	var prefersEnd: Bool
	
	public init(undoManager: UndoManager,
		 delegate: OutlineCommandDelegate,
		 outline: Outline,
		 rowGroups: [RowGroup],
		 afterRow: Row?,
		 prefersEnd: Bool) {
		
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rowGroups = rowGroups
		self.rows = [Row]()
		self.afterRow = afterRow
		self.prefersEnd = prefersEnd
		self.undoActionName = L10n.copy
		self.redoActionName = L10n.copy
	}
	
	public func perform() {
		saveCursorCoordinates()
		
		var newRows = [Row]()
		for rowGroup in rowGroups {
			let newRow = rowGroup.attach(to: outline)
			newRows.append(newRow)
		}
		rows = newRows
		
		outline.createRows(rows, afterRow: afterRow, prefersEnd: prefersEnd)
		registerUndo()
	}
	
	public func undo() {
		var allRows = [Row]()
		
		func deleteVisitor(_ visited: Row) {
			allRows.append(visited)
			visited.rows.forEach { $0.visit(visitor: deleteVisitor) }
		}
		rows.forEach { $0.visit(visitor: deleteVisitor(_:)) }

		outline.deleteRows(allRows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

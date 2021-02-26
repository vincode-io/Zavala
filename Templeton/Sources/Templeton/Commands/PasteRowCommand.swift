//
//  PasteRowCommand.swift
//  
//
//  Created by Maurice Parker on 12/31/20.
//

import Foundation
import RSCore

public final class PasteRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rowGroups: [RowGroup]
	var rows: [Row]
	var afterRow: Row?
	
	public init(undoManager: UndoManager,
		 delegate: OutlineCommandDelegate,
		 outline: Outline,
		 rowGroups: [RowGroup],
		 afterRow: Row?) {
		
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rowGroups = rowGroups
		self.rows = [Row]()
		self.afterRow = afterRow
		self.undoActionName = L10n.paste
		self.redoActionName = L10n.paste
	}
	
	public func perform() {
		saveCursorCoordinates()
		
		var newRows = [Row]()
		for rowGroup in rowGroups {
			let newRow = rowGroup.attach(to: outline)
			newRows.append(newRow)
		}
		rows = newRows
		
		outline.createRows(rows, afterRow: afterRow, prefersEnd: true)
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

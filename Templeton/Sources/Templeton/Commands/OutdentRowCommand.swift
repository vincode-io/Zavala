//
//  OutdentRowCommand.swift
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore

public final class OutdentRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]
	var restoreMoves = [Outline.RowMove]()
	var outdentedRows: [Row]?

	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.outdent
		self.redoActionName = L10n.outdent
		
		for row in rows {
			guard let oldParent = row.parent, let oldChildIndex = oldParent.firstIndexOfRow(row) else { continue }
			restoreMoves.append(Outline.RowMove(row: row, toParent: oldParent, toChildIndex: oldChildIndex))
		}
		
		if rows.count == 1, let row = rows.first {
			self.oldRowStrings = row.rowStrings
			self.newRowStrings = rowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		outdentedRows = outline.outdentRows(rows, rowStrings: newRowStrings)
		registerUndo()
	}
	
	public func undo() {
		guard let outdentedRows = outdentedRows else { return }
		let outdented = Set(outdentedRows)
		let outdentRestore = restoreMoves.filter { outdented.contains($0.row) }
		outline.moveRows(outdentRestore, rowStrings: oldRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

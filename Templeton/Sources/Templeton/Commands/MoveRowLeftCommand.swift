//
//  MoveRowLeftCommand.swift
//  
//
//  Created by Maurice Parker on 6/29/21.
//

import Foundation
import RSCore

public final class MoveRowLeftCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]
	var restoreMoves = [Outline.RowMove]()
	var moveLeftRows: [Row]?

	var oldRowStrings: RowStrings?
	var newRowStrings: RowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], rowStrings: RowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.moveLeft
		self.redoActionName = L10n.moveLeft
		
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
		moveLeftRows = outline.moveRowsLeft(rows, rowStrings: newRowStrings)
		registerUndo()
	}
	
	public func undo() {
		guard let moveLeftRows else { return }
		let movedLeft = Set(moveLeftRows)
		let moveLeftRestore = restoreMoves.filter { movedLeft.contains($0.row) }
		outline.moveRows(moveLeftRestore, rowStrings: oldRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

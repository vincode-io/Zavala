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
	var outdentedRows: [Row]?

	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row], textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.undoActionName = L10n.moveLeft
		self.redoActionName = L10n.moveRight
		
		for row in rows {
			guard let oldParent = row.parent, let oldChildIndex = oldParent.firstIndexOfRow(row) else { continue }
			restoreMoves.append(Outline.RowMove(row: row, toParent: oldParent, toChildIndex: oldChildIndex))
		}
		
		if rows.count == 1, let textRow = rows.first?.textRow {
			self.oldTextRowStrings = textRow.textRowStrings
			self.newTextRowStrings = textRowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		outdentedRows = outline.outdentRows(rows, textRowStrings: newTextRowStrings)
		registerUndo()
	}
	
	public func undo() {
		guard let outdentedRows = outdentedRows else { return }
		let outdented = Set(outdentedRows)
		let outdentRestore = restoreMoves.filter { outdented.contains($0.row) }
		outline.moveRows(outdentRestore, textRowStrings: oldTextRowStrings)
		registerRedo()
		restoreCursorPosition()
	}
	
}

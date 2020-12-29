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
	
	var outline: Outline
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
		self.undoActionName = L10n.outdent
		self.redoActionName = L10n.outdent
		
		for row in rows {
			guard let oldParent = row.parent, let oldChildIndex = oldParent.rows?.firstIndex(of: row) else { continue }
			restoreMoves.append(Outline.RowMove(row: row, toParent: oldParent, toChildIndex: oldChildIndex))
		}
		
		if rows.count == 1, let textRow = rows.first?.textRow {
			self.oldTextRowStrings = textRow.textRowStrings
			self.newTextRowStrings = textRowStrings
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		let (impacted, changes) = outline.outdentRows(rows, textRowStrings: newTextRowStrings)
		outdentedRows = impacted
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	public func undo() {
		guard let outdentedRows = outdentedRows else { return }
		let outdented = Set(outdentedRows)
		let outdentRestore = restoreMoves.filter { outdented.contains($0.row) }
		let changes = outline.moveRows(outdentRestore, textRowStrings: oldTextRowStrings)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

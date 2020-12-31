//
//  DropRowCommand.swift
//
//  Created by Maurice Parker on 12/16/20.
//

import Foundation
import RSCore

public final class LocalDropRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var changes: ShadowTableChanges?

	var outline: Outline
	var rowMoves = [Outline.RowMove]()
	var restoreMoves = [Outline.RowMove]()
	
	public init(undoManager: UndoManager,
		 delegate: OutlineCommandDelegate,
		 outline: Outline,
		 rows: [Row],
		 toParent: RowContainer,
		 toChildIndex: Int) {
		
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.undoActionName = L10n.move
		self.redoActionName = L10n.move

		for i in 0..<rows.count {
			let row = rows[i]
			rowMoves.append(Outline.RowMove(row: row, toParent: toParent, toChildIndex: toChildIndex + i))
			guard let oldParent = row.parent, let oldChildIndex = oldParent.rows?.firstIndex(of: row) else { continue }
			restoreMoves.append(Outline.RowMove(row: row, toParent: oldParent, toChildIndex: oldChildIndex))
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		changes = outline.moveRows(rowMoves, textRowStrings: nil)
		registerUndo()
	}
	
	public func undo() {
		let changes = outline.moveRows(restoreMoves, textRowStrings: nil)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

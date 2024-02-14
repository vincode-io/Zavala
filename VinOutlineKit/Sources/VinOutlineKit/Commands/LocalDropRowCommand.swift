//
//  DropRowCommand.swift
//
//  Created by Maurice Parker on 12/16/20.
//

import Foundation

public final class LocalDropRowCommand: OutlineCommand {
	
	var rowMoves = [Outline.RowMove]()
	var restoreMoves = [Outline.RowMove]()
	
	public init(actionName: String, undoManager: UndoManager,
		 delegate: OutlineCommandDelegate,
		 outline: Outline,
		 rows: [Row],
		 toParent: RowContainer,
		 toChildIndex: Int) {
		
		for i in 0..<rows.count {
			let row = rows[i]
			rowMoves.append(Outline.RowMove(row: row, toParent: toParent, toChildIndex: toChildIndex + i))
			guard let oldParent = row.parent, let oldChildIndex = oldParent.firstIndexOfRow(row) else { continue }
			restoreMoves.append(Outline.RowMove(row: row, toParent: oldParent, toChildIndex: oldChildIndex))
		}

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		outline.moveRows(rowMoves, rowStrings: nil)
	}
	
	public override func undo() {
		outline.moveRows(restoreMoves, rowStrings: nil)
	}
	
}

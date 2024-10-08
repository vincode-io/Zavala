//
//  Created by Maurice Parker on 9/14/24.
//

import Foundation

public final class SortRowsCommand: OutlineCommand {
	
	var rowMoves = [Outline.RowMove]()
	var restoreMoves = [Outline.RowMove]()
	
	public init(actionName: String,
				undoManager: UndoManager,
				delegate: OutlineCommandDelegate,
				outline: Outline,
				rows: [Row]) {
		
		let displayOrderRows = rows.sortedByDisplayOrder()
		
		for row in displayOrderRows {
			guard let parent = row.parent, let index = parent.firstIndexOfRow(row) else { continue }
			restoreMoves.append(Outline.RowMove(row: row, toParent: parent, toChildIndex: index))
		}

		let sortedRows = rows.sorted { left, right in
			return (left.topic?.string ?? "").caseInsensitiveCompare(right.topic?.string ?? "") == .orderedAscending
		}
		
		let startIndex = displayOrderRows.first!.parent!.firstIndexOfRow(displayOrderRows.first!) ?? 0
		
		for i in 0..<sortedRows.count {
			let row = sortedRows[i]
			guard let parent = row.parent else { continue }
			rowMoves.append(Outline.RowMove(row: row, toParent: parent, toChildIndex: startIndex + i))
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

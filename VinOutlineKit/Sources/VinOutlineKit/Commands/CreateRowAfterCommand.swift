//
//  CreateRowAfterCommand.swift
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation

public final class CreateRowAfterCommand: OutlineCommand {

	var row: Row?
	var afterRow: Row?
	var rowStrings: RowStrings?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, afterRow: Row?, rowStrings: RowStrings?) {
		self.afterRow = afterRow
		self.rowStrings = rowStrings

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	override public func perform() {
		if row == nil {
			row = Row(outline: outline)
		}
		outline.createRow(row!, afterRow: afterRow, rowStrings: rowStrings)
	}
	
	override public func undo() {
		guard let row else { return }
		outline.deleteRows([row])
	}
	
}

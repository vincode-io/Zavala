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
	var childRowIndent: Bool

	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, afterRow: Row?, rowStrings: RowStrings?, childRowIndent: Bool) {
		self.afterRow = afterRow
		self.rowStrings = rowStrings
		self.childRowIndent = childRowIndent

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	override public func perform() {
		if row == nil {
			row = Row(outline: outline)
		}
		outline.createRow(row!, afterRow: afterRow, rowStrings: rowStrings, childRowIndent: childRowIndent)
	}
	
	override public func undo() {
		guard let row else { return }
		outline.deleteRows([row])
	}
	
}

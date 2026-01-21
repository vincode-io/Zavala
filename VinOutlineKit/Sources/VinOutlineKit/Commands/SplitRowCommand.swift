//
//  SplitRowCommand.swift
//
//  Created by Maurice Parker on 12/5/20.
//

import Foundation

public final class SplitRowCommand: OutlineCommand {

	var newRow: Row?
	var row: Row
	var topic: NSAttributedString
	var cursorPosition: Int
	var childRowIndent: Bool

	public init(actionName: String,
				undoManager: UndoManager,
				delegate: OutlineCommandDelegate,
				outline: Outline,
				row: Row,
				topic: NSAttributedString,
				cursorPosition: Int,
				childRowIndent: Bool) {
		self.row = row
		self.topic = topic
		self.cursorPosition = cursorPosition
		self.childRowIndent = childRowIndent

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		if newRow == nil {
			newRow = Row(outline: outline)
		}
		outline.splitRow(newRow: newRow!, row: row, topic: topic, cursorPosition: cursorPosition, childRowIndent: childRowIndent)
	}
	
	public override func undo() {
		guard let newRow else { return }
		outline.joinRows(topRow: row, bottomRow: newRow, topic: topic)
	}
	
}

//
//  File.swift
//  
//
//  Created by Maurice Parker on 4/11/24.
//

import Foundation

public final class JoinRowCommand: OutlineCommand {

	var topRow: Row
	var bottomRow: Row
	var topic: NSAttributedString
	var undoTopic: NSAttributedString
	var splitCursorPosition: Int
	
	var restoreParent: RowContainer?
	var restoreIndex: Int?
	
	public init(actionName: String,
				undoManager: UndoManager,
				delegate: OutlineCommandDelegate,
				outline: Outline,
				topRow: Row,
				bottomRow: Row,
				topic: NSAttributedString) {
		self.topRow = topRow
		self.bottomRow = bottomRow
		self.topic = topic
		
		let attrString = NSMutableAttributedString(attributedString: topRow.topic ?? NSAttributedString())
		attrString.append(bottomRow.topic ?? NSAttributedString())
		self.undoTopic = attrString
		
		self.splitCursorPosition = topRow.topic?.length ?? 0
		
		self.restoreParent = bottomRow.parent
		self.restoreIndex = bottomRow.parent?.firstIndexOfRow(bottomRow)

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		outline.joinRows(topRow: topRow, bottomRow: bottomRow, topic: topic)
	}
	
	public override func undo() {
		outline.splitRow(newRow: bottomRow, toParent: restoreParent, toIndex: restoreIndex, row: topRow, topic: undoTopic, cursorPosition: splitCursorPosition)
	}
	
}

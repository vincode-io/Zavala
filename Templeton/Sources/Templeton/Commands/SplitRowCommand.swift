//
//  SplitRowCommand.swift
//
//  Created by Maurice Parker on 12/5/20.
//

import Foundation
import RSCore

public final class SplitRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var newCursorIndex: Int?

	public var outline: Outline
	var newRow: Row?
	var row: Row
	var topic: NSAttributedString
	var cursorPosition: Int
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, row: Row, topic: NSAttributedString, cursorPosition: Int) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.topic = topic
		self.cursorPosition = cursorPosition
		undoActionName = L10n.splitRow
		redoActionName = L10n.splitRow
	}
	
	public func perform() {
		saveCursorCoordinates()
		if newRow == nil {
			newRow = Row.text(TextRow(outline: outline))
		}
		newCursorIndex = outline.splitRow(newRow: newRow!, row: row, topic: topic, cursorPosition: cursorPosition)
		registerUndo()
	}
	
	public func undo() {
		guard let newHeadline = newRow else { return }
		outline.joinRows(topRow: row, bottomRow: newHeadline)
		registerRedo()
		restoreCursorPosition()
	}
	
}

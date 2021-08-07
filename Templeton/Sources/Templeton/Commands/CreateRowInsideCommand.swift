//
//  CreateRowInsideCommand.swift
//  
//
//  Created by Maurice Parker on 6/30/21.
//

import Foundation
import RSCore

public final class CreateRowInsideCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	public weak var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var newCursorIndex: Int?

	public var outline: Outline
	var row: Row?
	var afterRow: Row
	var textRowStrings: TextRowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, afterRow: Row, textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.afterRow = afterRow
		self.textRowStrings = textRowStrings
		undoActionName = L10n.addRowInside
		redoActionName = L10n.addRowInside
	}
	
	public func perform() {
		saveCursorCoordinates()
		if row == nil {
			row = Row.text(TextRow(outline: outline))
		}
		newCursorIndex = outline.createRowInside(row!, afterRow: afterRow, textRowStrings: textRowStrings)
		registerUndo()
	}
	
	public func undo() {
		guard let row = row else { return }
		outline.deleteRows([row])
		registerRedo()
		restoreCursorPosition()
	}
	
}

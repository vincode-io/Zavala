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
	var row: Row
	var oldParent: Row?
	var oldChildIndex: Int?
	var oldTextRowStrings: TextRowStrings?
	var newTextRowStrings: TextRowStrings
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, row: Row, textRowStrings: TextRowStrings) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.undoActionName = L10n.outdent
		self.redoActionName = L10n.outdent
		
		// This is going to move, so we save the parent and child index
		if row != row.parent?.rows?.last {
			self.oldParent = row.parent as? Row
			self.oldChildIndex = row.parent?.rows?.firstIndex(of: row)
		}
		
		self.oldTextRowStrings = row.textRow?.textRowStrings
		self.newTextRowStrings = textRowStrings
	}
	
	public func perform() {
		saveCursorCoordinates()
		let changes = outline.outdentRow(row, textRowStrings: newTextRowStrings)
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	public func undo() {
		if let oldParent = oldParent, let oldChildIndex = oldChildIndex {
			let changes = outline.moveRow(row, textRowStrings: oldTextRowStrings, toParent: oldParent, childIndex: oldChildIndex)
			delegate?.applyChangesRestoringCursor(changes)
		} else {
			let changes = outline.indentRow(row, textRowStrings: oldTextRowStrings)
			delegate?.applyChangesRestoringCursor(changes)
		}
		registerRedo()
		restoreCursorPosition()
	}
	
}

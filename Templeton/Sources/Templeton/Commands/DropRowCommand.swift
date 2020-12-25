//
//  DropRowCommand.swift
//
//  Created by Maurice Parker on 12/16/20.
//

import Foundation
import RSCore

public final class DropRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var changes: ShadowTableChanges?

	var outline: Outline
	var row: Row
	var oldParent: RowContainer?
	var oldChildIndex: Int?
	var toParent: RowContainer
	var toChildIndex: Int
	
	public init(undoManager: UndoManager,
		 delegate: OutlineCommandDelegate,
		 outline: Outline,
		 row: Row,
		 toParent: RowContainer,
		 toChildIndex: Int) {
		
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.row = row
		self.toParent = toParent
		self.toChildIndex = toChildIndex
		self.undoActionName = L10n.move
		self.redoActionName = L10n.move

		oldParent = row.parent
		oldChildIndex = oldParent?.rows?.firstIndex(of: row)
	}
	
	public func perform() {
		saveCursorCoordinates()
		changes = outline.moveRow(row, toParent: toParent, childIndex: toChildIndex)
		registerUndo()
	}
	
	public func undo() {
		if let oldParent = oldParent, let oldChildIndex = oldChildIndex {
			let changes = outline.moveRow(row, toParent: oldParent, childIndex: oldChildIndex)
			delegate?.applyChangesRestoringCursor(changes)
		}
		registerRedo()
		restoreCursorPosition()
	}
	
}

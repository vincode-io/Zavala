//
//  EditorDropRowCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 12/16/20.
//

import Foundation
import RSCore
import Templeton

final class EditorDropRowCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var row: Row
	var oldParent: RowContainer?
	var oldChildIndex: Int?
	var toParent: RowContainer
	var toChildIndex: Int
	var shadowTableChanges: ShadowTableChanges?
	
	init(undoManager: UndoManager,
		 delegate: EditorOutlineCommandDelegate,
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
	
	func perform() {
		saveCursorCoordinates()
		shadowTableChanges = outline.moveRow(row, toParent: toParent, childIndex: toChildIndex)
		registerUndo()
	}
	
	func undo() {
		if let oldParent = oldParent, let oldChildIndex = oldChildIndex {
			let changes = outline.moveRow(row, toParent: oldParent, childIndex: oldChildIndex)
			delegate?.applyChangesRestoringCursor(changes)
		}
		registerRedo()
		restoreCursorPosition()
	}
	
}

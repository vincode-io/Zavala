//
//  EditorCollapseAllCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 12/20/20.
//

import Foundation
import RSCore
import Templeton

final class EditorCollapseAllCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var container: RowContainer
	var collapsedRows: [Row]?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, container: RowContainer) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.container = container
		if container is Outline {
			undoActionName = L10n.collapseAllInOutline
			redoActionName = L10n.collapseAllInOutline
		} else {
			undoActionName = L10n.collapseAll
			redoActionName = L10n.collapseAll
		}
	}
	
	func perform() {
		saveCursorCoordinates()
		let (expanded, changes) = outline.collapseAll(container: container)
		collapsedRows = expanded
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	func undo() {
		guard let collapsedRows = collapsedRows else { return }
		let changes = outline.expand(rows: collapsedRows)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

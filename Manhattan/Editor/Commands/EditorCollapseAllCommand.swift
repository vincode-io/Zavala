//
//  EditorCollapseAllCommand.swift
//  Manhattan
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
	var container: HeadlineContainer
	var expandedHeadlines: [Headline]?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, container: HeadlineContainer) {
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
		expandedHeadlines = expanded
		delegate?.applyChanges(changes)
		registerUndo()
	}
	
	func undo() {
//		let changes = outline.toggleDisclosure(headline: headline)
//		delegate?.applyChanges(changes)
//		registerRedo()
//		restoreCursorPosition()
	}
	
}

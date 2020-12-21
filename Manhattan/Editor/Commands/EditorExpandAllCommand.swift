//
//  EditorExpandAllCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/20/20.
//

import Foundation
import RSCore
import Templeton

final class EditorExpandAllCommand: EditorOutlineCommand {
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
			undoActionName = L10n.expandAllInOutline
			redoActionName = L10n.expandAllInOutline
		} else {
			undoActionName = L10n.expandAll
			redoActionName = L10n.expandAll
		}
	}
	
	func perform() {
		saveCursorCoordinates()
		let (expanded, changes) = outline.expandAll(container: container)
		expandedHeadlines = expanded
		delegate?.applyChanges(changes)
		registerUndo()
	}
	
	func undo() {
		guard let expandedHeadlines = expandedHeadlines else { return }
		let changes = outline.collapse(headlines: expandedHeadlines)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

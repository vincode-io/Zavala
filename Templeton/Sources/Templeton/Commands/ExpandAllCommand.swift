//
//  ExpandAllCommand.swift
//
//  Created by Maurice Parker on 12/20/20.
//

import Foundation
import RSCore

public final class ExpandAllCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var container: RowContainer
	var expandedRows: [Row]?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, container: RowContainer) {
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
	
	public func perform() {
		saveCursorCoordinates()
		let (expanded, changes) = outline.expandAll(container: container)
		expandedRows = expanded
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	public func undo() {
		guard let expandedHeadlines = expandedRows else { return }
		let changes = outline.collapse(rows: expandedHeadlines)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

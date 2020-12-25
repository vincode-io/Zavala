//
//  CollapseAllCommand.swift
//
//  Created by Maurice Parker on 12/20/20.
//

import Foundation
import RSCore

public final class CollapseAllCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	public weak var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var container: RowContainer
	var collapsedRows: [Row]?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, container: RowContainer) {
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
	
	public func perform() {
		saveCursorCoordinates()
		let (expanded, changes) = outline.collapseAll(container: container)
		collapsedRows = expanded
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	public func undo() {
		guard let collapsedRows = collapsedRows else { return }
		let changes = outline.expand(rows: collapsedRows)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

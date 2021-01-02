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
	var containers: [RowContainer]
	var expandedRows: [Row]?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, containers: [RowContainer]) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.containers = containers
		if containers.first is Outline {
			undoActionName = L10n.expandAllInOutline
			redoActionName = L10n.expandAllInOutline
		} else {
			undoActionName = L10n.expandAll
			redoActionName = L10n.expandAll
		}
	}
	
	public func perform() {
		saveCursorCoordinates()
		expandedRows = outline.expandAll(containers: containers)
		registerUndo()
	}
	
	public func undo() {
		guard let expandedRows = expandedRows else { return }
		outline.collapse(rows: expandedRows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

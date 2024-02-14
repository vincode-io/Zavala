//
//  ExpandAllCommand.swift
//
//  Created by Maurice Parker on 12/20/20.
//

import Foundation

public final class ExpandAllCommand: OutlineCommand {
	
	var containers: [RowContainer]
	var expandedRows: [Row]?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, containers: [RowContainer]) {
		self.containers = containers

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		saveCursorCoordinates()
		expandedRows = outline.expandAll(containers: containers)
		registerUndo()
	}
	
	public override func undo() {
		guard let expandedRows else { return }
		outline.collapse(rows: expandedRows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

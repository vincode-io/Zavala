//
//  CollapseAllCommand.swift
//
//  Created by Maurice Parker on 12/20/20.
//

import Foundation

public final class CollapseAllCommand: OutlineCommand {
	var containers: [RowContainer]
	var collapsedRows: [Row]?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, containers: [RowContainer]) {
		self.containers = containers
		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		saveCursorCoordinates()
		collapsedRows = outline.collapseAll(containers: containers)
		registerUndo()
	}
	
	public override func undo() {
		guard let collapsedRows else { return }
		outline.expand(rows: collapsedRows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

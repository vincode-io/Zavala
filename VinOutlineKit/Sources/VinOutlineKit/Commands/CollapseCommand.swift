//
//  CollapseCommand.swift
//  
//
//  Created by Maurice Parker on 12/28/20.
//

import Foundation

public final class CollapseCommand: OutlineCommand {
	var rows: [Row]
	var collapsedRows: [Row]?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row]) {
		self.rows = rows
		
		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	override public func perform() {
		saveCursorCoordinates()
		collapsedRows = outline.collapse(rows: rows)
		registerUndo()
	}
	
	override public func undo() {
		guard let expandedRows = collapsedRows else { return }
		outline.expand(rows: expandedRows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

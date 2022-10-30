//
//  ExpandCommand.swift
//  
//
//  Created by Maurice Parker on 12/28/20.
//

import Foundation
import RSCore

public final class ExpandCommand: OutlineCommand {
	var rows: [Row]
	var expandedRows: [Row]?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row]) {
		self.rows = rows

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		saveCursorCoordinates()
		expandedRows = outline.expand(rows: rows)
		registerUndo()
	}
	
	public override func undo() {
		guard let expandedRows else { return }
		outline.collapse(rows: expandedRows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

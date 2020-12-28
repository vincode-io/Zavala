//
//  CollapseCommand.swift
//  
//
//  Created by Maurice Parker on 12/28/20.
//

import Foundation
import RSCore

public final class CollapseCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var rows: [Row]
	var collapsedRows: [Row]?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row]) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		undoActionName = L10n.collapse
		redoActionName = L10n.collapse
	}
	
	public func perform() {
		saveCursorCoordinates()
		let (impacted, changes) = outline.collapse(rows: rows)
		collapsedRows = impacted
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	public func undo() {
		guard let expandedRows = collapsedRows else { return }
		let (_, changes) = outline.expand(rows: expandedRows)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

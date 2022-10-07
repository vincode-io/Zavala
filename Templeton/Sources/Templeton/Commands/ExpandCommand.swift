//
//  ExpandCommand.swift
//  
//
//  Created by Maurice Parker on 12/28/20.
//

import Foundation
import RSCore

public final class ExpandCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]
	var expandedRows: [Row]?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, rows: [Row]) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		undoActionName = L10n.expand
		redoActionName = L10n.expand
	}
	
	public func perform() {
		saveCursorCoordinates()
		expandedRows = outline.expand(rows: rows)
		registerUndo()
	}
	
	public func undo() {
		guard let expandedRows else { return }
		outline.collapse(rows: expandedRows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

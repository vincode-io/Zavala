//
//  PasteRowCommand.swift
//  
//
//  Created by Maurice Parker on 12/31/20.
//

import Foundation
import RSCore

public final class PasteRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]
	var afterRow: Row?
	
	public init(undoManager: UndoManager,
		 delegate: OutlineCommandDelegate,
		 outline: Outline,
		 rows: [Row],
		 afterRow: Row?) {
		
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.afterRow = afterRow
		self.undoActionName = L10n.paste
		self.redoActionName = L10n.paste
	}
	
	public func perform() {
		saveCursorCoordinates()
		outline.createRows(rows, afterRow: afterRow, prefersEnd: true)
		registerUndo()
	}
	
	public func undo() {
		outline.deleteRows(rows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

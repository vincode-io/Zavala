//
//  RemoteDropRowCommand.swift
//  
//
//  Created by Maurice Parker on 12/30/20.
//

import Foundation
import RSCore

public final class RemoteDropRowCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var outline: Outline
	var rows: [Row]
	var afterRow: Row?
	var prefersEnd: Bool
	
	public init(undoManager: UndoManager,
		 delegate: OutlineCommandDelegate,
		 outline: Outline,
		 rows: [Row],
		 afterRow: Row?,
		 prefersEnd: Bool) {
		
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.rows = rows
		self.afterRow = afterRow
		self.prefersEnd = prefersEnd
		self.undoActionName = L10n.copy
		self.redoActionName = L10n.copy
	}
	
	public func perform() {
		saveCursorCoordinates()
		outline.createRows(rows, afterRow: afterRow, prefersEnd: prefersEnd)
		registerUndo()
	}
	
	public func undo() {
		outline.deleteRows(rows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

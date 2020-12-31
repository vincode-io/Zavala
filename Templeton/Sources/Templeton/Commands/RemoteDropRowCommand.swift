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
	
	var outline: Outline
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
		self.undoActionName = L10n.copy
		self.redoActionName = L10n.copy
	}
	
	public func perform() {
		saveCursorCoordinates()
		let changes = outline.createRows(rows, afterRow: afterRow)
		delegate?.applyChanges(changes)
		registerUndo()
	}
	
	public func undo() {
		let changes = outline.deleteRows(rows)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

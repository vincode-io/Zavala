//
//  RemoteDropTextCommand.swift
//  
//
//  Created by Maurice Parker on 1/2/21.
//

import Foundation

public final class RemoteDropTextCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var text: String
	var afterRow: Row?
	var rows: [Row]?

	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, text: String, afterRow: Row?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.text = text
		self.afterRow = afterRow
		self.undoActionName = L10n.copy
		self.redoActionName = L10n.copy
	}
	
	public func perform() {
		saveCursorCoordinates()
		rows = outline.createRows(text: text, afterRow: afterRow)
		registerUndo()
	}
	
	public func undo() {
		guard let rows = rows else { return }
		outline.deleteRows(rows)
		registerRedo()
		restoreCursorPosition()
	}
	
}

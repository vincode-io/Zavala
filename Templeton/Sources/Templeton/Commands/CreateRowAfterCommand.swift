//
//  CreateRowAfterCommand.swift
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore

public final class CreateRowAfterCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	public weak var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var changes: ShadowTableChanges?

	var outline: Outline
	var row: Row?
	var afterRow: Row?
	var textRowStrings: TextRowStrings?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, afterRow: Row?, textRowStrings: TextRowStrings?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.afterRow = afterRow
		self.textRowStrings = textRowStrings
		undoActionName = L10n.addRow
		redoActionName = L10n.addRow
	}
	
	public func perform() {
		saveCursorCoordinates()
		if row == nil {
			row = Row.text(TextRow())
		}
		changes = outline.createRows([row!], afterRow: afterRow, textRowStrings: textRowStrings)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	public func undo() {
		guard let row = row else { return }
		let changes = outline.deleteRows([row])
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

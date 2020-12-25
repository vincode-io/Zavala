//
//  EditorSplitHeadlineCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 12/5/20.
//

import Foundation
import RSCore
import Templeton

final class EditorSplitHeadlineCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var newHeadline: TextRow?
	var headline: TextRow
	var topic: NSAttributedString
	var cursorPosition: Int
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: TextRow, topic: NSAttributedString, cursorPosition: Int) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.topic = topic
		self.cursorPosition = cursorPosition
		undoActionName = L10n.splitRow
		redoActionName = L10n.splitRow
	}
	
	func perform() {
		saveCursorCoordinates()
		if newHeadline == nil {
			newHeadline = TextRow()
		}
		changes = outline.splitRow(newRow: newHeadline!, row: headline, topic: topic, cursorPosition: cursorPosition)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		guard let newHeadline = newHeadline else { return }
		let changes = outline.joinRows(topRow: headline, bottomRow: newHeadline)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

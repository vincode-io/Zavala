//
//  EditorCreateHeadlineBeforeCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/15/20.
//

import Foundation
import RSCore
import Templeton

final class EditorCreateHeadlineBeforeCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var headline: Headline
	var beforeHeadline: Headline
	var attributedTexts: HeadlineTexts?
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, beforeHeadline: Headline, attributedTexts: HeadlineTexts?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = Headline()
		self.beforeHeadline = beforeHeadline
		self.attributedTexts = attributedTexts
		undoActionName = L10n.addRow
		redoActionName = L10n.addRow
	}
	
	func perform() {
		saveCursorCoordinates()
		changes = outline.createHeadline(headline: headline, beforeHeadline: beforeHeadline)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.deleteHeadline(headline: headline)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

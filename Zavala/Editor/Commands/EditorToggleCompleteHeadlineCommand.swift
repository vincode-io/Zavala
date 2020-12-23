//
//  EditorToggleCompleteHeadlineCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 11/30/20.
//

import Foundation
import RSCore
import Templeton

final class EditorToggleCompleteHeadlineCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var headline: Headline
	var oldAttributedTexts: HeadlineTexts
	var newAttributedTexts: HeadlineTexts
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline, attributedTexts: HeadlineTexts) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.undoActionName = L10n.complete
		self.redoActionName = L10n.complete
		
		oldAttributedTexts = headline.attributedTexts
		newAttributedTexts = attributedTexts
	}
	
	func perform() {
		saveCursorCoordinates()
		changes = outline.toggleComplete(headline: headline, attributedTexts: newAttributedTexts)
		delegate?.applyChangesRestoringCursor(changes!)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.toggleComplete(headline: headline, attributedTexts: oldAttributedTexts)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

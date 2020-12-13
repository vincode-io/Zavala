//
//  EditorIndentHeadlineCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorIndentHeadlineCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager

	weak var delegate: EditorOutlineCommandDelegate?
	var outline: Outline
	var headline: Headline
	var oldAttributedTexts: HeadlineTexts
	var newAttributedTexts: HeadlineTexts
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline, attributedTexts: HeadlineTexts) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.undoActionName = L10n.indent
		self.redoActionName = L10n.indent
		
		oldAttributedTexts = headline.attributedTexts
		newAttributedTexts = attributedTexts
	}
	
	func perform() {
		let changes = outline.indentHeadline(headline: headline, attributedTexts: newAttributedTexts)
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.outdentHeadline(headline: headline, attributedTexts: oldAttributedTexts)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
	}
	
}

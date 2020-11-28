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
	var oldAttributedText: NSAttributedString
	var newAttributedText: NSAttributedString
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline, attributedText: NSAttributedString) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.undoActionName = L10n.indent
		self.redoActionName = L10n.indent
		
		if headline.attributedText == nil {
			oldAttributedText = NSAttributedString()
		} else {
			oldAttributedText = headline.attributedText!
		}
		newAttributedText = attributedText
	}
	
	func perform() {
		let changes = outline.indentHeadline(headline: headline, attributedText: newAttributedText)
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.outdentHeadline(headline: headline, attributedText: oldAttributedText)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
	}
	
}

//
//  EditorTextChangedCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorTextChangedCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager

	weak var delegate: EditorOutlineCommandDelegate?
	var outline: Outline
	var headline: Headline
	var oldAttributedText: NSAttributedString
	var newAttributedText: NSAttributedString
	var applyChanges = false
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline, attributedText: NSAttributedString) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.undoActionName = L10n.typing
		self.redoActionName = L10n.typing
		
		if headline.attributedText == nil {
			oldAttributedText = NSAttributedString()
		} else {
			oldAttributedText = headline.attributedText!
		}
		newAttributedText = attributedText
	}
	
	func perform() {
		let changes = outline.updateHeadline(headline: headline, attributedText: newAttributedText)
		if applyChanges {
			delegate?.applyChangesRestoringCursor(changes)
		}
		applyChanges = true
		registerUndo()
	}
	
	func undo() {
		let changes = outline.updateHeadline(headline: headline, attributedText: oldAttributedText)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
	}
	
}

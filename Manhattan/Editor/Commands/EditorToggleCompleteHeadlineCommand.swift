//
//  EditorToggleCompleteHeadlineCommand.swift
//  Manhattan
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
	var outline: Outline
	var headline: Headline
	var oldAttributedText: NSAttributedString
	var newAttributedText: NSAttributedString
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline, attributedText: NSAttributedString) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.undoActionName = L10n.complete
		self.redoActionName = L10n.complete
		
		if headline.attributedText == nil {
			oldAttributedText = NSAttributedString()
		} else {
			oldAttributedText = headline.attributedText!
		}
		newAttributedText = attributedText
	}
	
	func perform() {
		changes = outline.toggleComplete(headline: headline, attributedText: newAttributedText)
		delegate?.applyChangesRestoringCursor(changes!)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.toggleComplete(headline: headline, attributedText: oldAttributedText)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
	}
	
}

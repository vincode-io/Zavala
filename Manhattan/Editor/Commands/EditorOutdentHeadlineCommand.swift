//
//  EditorOutdentHeadlineCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorOutdentHeadlineCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager

	weak var delegate: EditorOutlineCommandDelegate?
	var outline: Outline
	var headline: Headline
	var oldParent: Headline?
	var oldChildIndex: Int?
	var oldAttributedText: NSAttributedString
	var newAttributedText: NSAttributedString
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline, attributedText: NSAttributedString) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.undoActionName = L10n.outdent
		self.redoActionName = L10n.outdent
		
		// This is going to move, so we save the parent and child index
		if headline != headline.parent?.headlines?.last {
			oldParent = headline.parent as? Headline
			oldChildIndex = headline.parent?.headlines?.firstIndex(of: headline)
		}
		
		if headline.attributedText == nil {
			oldAttributedText = NSAttributedString()
		} else {
			oldAttributedText = headline.attributedText!
		}
		newAttributedText = attributedText
	}
	
	func perform() {
		let changes = outline.outdentHeadline(headline: headline, attributedText: newAttributedText)
		delegate?.applyChangesRestoringCursor(changes)
		registerUndo()
	}
	
	func undo() {
		if let oldParent = oldParent, let oldChildIndex = oldChildIndex {
			let changes = outline.moveHeadline(headline, attributedText: oldAttributedText, toParent: oldParent, childIndex: oldChildIndex)
			delegate?.applyChangesRestoringCursor(changes)
		} else {
			let changes = outline.indentHeadline(headline: headline, attributedText: oldAttributedText)
			delegate?.applyChangesRestoringCursor(changes)
		}
		registerRedo()
	}
	
}

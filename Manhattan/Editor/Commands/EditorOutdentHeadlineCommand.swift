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
		
		if headline != headline.parent?.headlines?.last {
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
		let changes = outline.indentHeadline(headline: headline, attributedText: oldAttributedText, childIndex: oldChildIndex)
		delegate?.applyChangesRestoringCursor(changes)
		registerRedo()
	}
	
}

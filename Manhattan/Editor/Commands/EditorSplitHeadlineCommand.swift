//
//  EditorSplitHeadlineCommand.swift
//  Manhattan
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
	var outline: Outline
	var newHeadline: Headline?
	var headline: Headline
	var attributedText: NSAttributedString
	var cursorPosition: Int
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline, attributedText: NSAttributedString, cursorPosition: Int) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.attributedText = attributedText
		self.cursorPosition = cursorPosition
		undoActionName = L10n.splitRow
		redoActionName = L10n.splitRow
	}
	
	func perform() {
		if newHeadline == nil {
			newHeadline = Headline()
		}
		changes = outline.splitHeadline(newHeadline: newHeadline!, headline: headline, attributedText: attributedText, cursorPosition: cursorPosition)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		guard let newHeadline = newHeadline else { return }
		let changes = outline.joinHeadline(topHeadline: headline, bottomHeadline: newHeadline)
		delegate?.applyChanges(changes)
		registerRedo()
	}
	
}

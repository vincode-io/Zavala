//
//  EditorCreateHeadlineCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorCreateHeadlineCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager

	weak var delegate: EditorOutlineCommandDelegate?
	var outline: Outline
	var headline: Headline?
	var afterHeadline: Headline?
	var attributedTexts: HeadlineTexts?
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, afterHeadline: Headline?, attributedTexts: HeadlineTexts?) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.afterHeadline = afterHeadline
		self.attributedTexts = attributedTexts
		undoActionName = L10n.delete
		redoActionName = L10n.delete
	}
	
	func perform() {
		if headline == nil {
			headline = Headline()
		}
		changes = outline.createHeadline(headline: headline!, afterHeadline: afterHeadline, attributedTexts: attributedTexts)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		guard let headline = headline else { return }
		let changes = outline.deleteHeadline(headline: headline)
		delegate?.applyChanges(changes)
		registerRedo()
	}
	
}

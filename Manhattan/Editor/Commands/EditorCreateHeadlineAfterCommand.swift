//
//  EditorCreateHeadlineCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorCreateHeadlineAfterCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
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
		undoActionName = L10n.addRow
		redoActionName = L10n.addRow
	}
	
	func perform() {
		saveCursorCoordinates()
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
		restoreCursorPosition()
	}
	
}

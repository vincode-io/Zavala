//
//  EditorDeleteHeadlineCommand.swift
//  Zavala
//
//  Created by Maurice Parker on 11/28/20.
//

import Foundation
import RSCore
import Templeton

final class EditorDeleteHeadlineCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var headline: Headline
	var attributedTexts: HeadlineTexts
	var afterHeadline: Headline?
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline, attributedTexts: HeadlineTexts) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.attributedTexts = attributedTexts
		undoActionName = L10n.delete
		redoActionName = L10n.delete
	}
	
	func perform() {
		saveCursorCoordinates()
		if let headlineShadowTableIndex = headline.shadowTableIndex, headlineShadowTableIndex > 0 {
			afterHeadline = outline.shadowTable?[headlineShadowTableIndex - 1]
		}
		
		changes = outline.deleteHeadline(headline: headline, attributedTexts: attributedTexts)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.createHeadline(headline: headline, afterHeadline: afterHeadline)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

//
//  EditorDeleteNoteCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/13/20.
//

import Foundation
import RSCore
import Templeton

final class EditorDeleteNoteCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager
	weak var delegate: EditorOutlineCommandDelegate?
	var cursorCoordinates: CursorCoordinates?
	
	var outline: Outline
	var headline: Headline
	var oldAttributedTexts: HeadlineTexts
	var newAttributedTexts: HeadlineTexts
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline, attributedTexts: HeadlineTexts) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.oldAttributedTexts = headline.attributedTexts
		self.newAttributedTexts = attributedTexts
		undoActionName = L10n.deleteNote
		redoActionName = L10n.deleteNote
	}
	
	func perform() {
		saveCursorCoordinates()
		changes = outline.deleteNote(headline: headline, attributedTexts: newAttributedTexts)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.createNote(headline: headline, attributedTexts: oldAttributedTexts)
		delegate?.applyChanges(changes)
		registerRedo()
		restoreCursorPosition()
	}
	
}

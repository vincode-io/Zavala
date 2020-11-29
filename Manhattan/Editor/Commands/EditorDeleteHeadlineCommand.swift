//
//  EditorDeleteHeadlineCommand.swift
//  Manhattan
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
	var outline: Outline
	var headline: Headline
	var afterHeadline: Headline?
	var changes: ShadowTableChanges?
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		undoActionName = L10n.delete
		redoActionName = L10n.delete
	}
	
	func perform() {
		if let headlineShadowTableIndex = headline.shadowTableIndex, headlineShadowTableIndex > 0 {
			afterHeadline = outline.shadowTable?[headlineShadowTableIndex - 1]
		}
		
		changes = outline.deleteHeadline(headline: headline)
		delegate?.applyChanges(changes!)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.createHeadline(headline: headline, afterHeadline: afterHeadline)
		delegate?.applyChanges(changes)
		registerRedo()
	}
	
}

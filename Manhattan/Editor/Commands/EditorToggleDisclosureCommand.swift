//
//  EditorToggleDisclosureCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/27/20.
//

import Foundation
import RSCore
import Templeton

final class EditorToggleDisclosureCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager

	weak var delegate: EditorOutlineCommandDelegate?
	var outline: Outline
	var headline: Headline
	
	init(undoManager: UndoManager, delegate: EditorOutlineCommandDelegate, outline: Outline, headline: Headline) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		if headline.isExpanded ?? true {
			undoActionName = L10n.collapse
			redoActionName = L10n.collapse
		} else {
			undoActionName = L10n.expand
			redoActionName = L10n.expand
		}
	}
	
	func perform() {
		let changes = outline.toggleDisclosure(headline: headline)
		delegate?.applyShadowTableChanges(changes)
		registerUndo()
	}
	
	func undo() {
		let changes = outline.toggleDisclosure(headline: headline)
		delegate?.applyShadowTableChanges(changes)
		registerRedo()
	}
	
}

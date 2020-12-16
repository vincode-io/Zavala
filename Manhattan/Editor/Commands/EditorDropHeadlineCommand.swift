//
//  EditorDropHeadlineCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/16/20.
//

import Foundation
import RSCore
import Templeton

final class EditorDropHeadlineCommand: EditorOutlineCommand {
	var undoActionName: String
	var redoActionName: String
	var undoManager: UndoManager

	weak var delegate: EditorOutlineCommandDelegate?
	var outline: Outline
	var headline: Headline
	var oldParent: HeadlineContainer?
	var oldChildIndex: Int?
	var toParent: HeadlineContainer
	var toChildIndex: Int
	var shadowTableChanges: ShadowTableChanges?
	
	init(undoManager: UndoManager,
		 delegate: EditorOutlineCommandDelegate,
		 outline: Outline,
		 headline: Headline,
		 toParent: HeadlineContainer,
		 toChildIndex: Int) {
		
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.headline = headline
		self.toParent = toParent
		self.toChildIndex = toChildIndex
		self.undoActionName = L10n.move
		self.redoActionName = L10n.move

		oldParent = headline.parent
		oldChildIndex = oldParent?.headlines?.firstIndex(of: headline)
	}
	
	func perform() {
		shadowTableChanges = outline.moveHeadline(headline, toParent: toParent, childIndex: toChildIndex)
		registerUndo()
	}
	
	func undo() {
		if let oldParent = oldParent, let oldChildIndex = oldChildIndex {
			let changes = outline.moveHeadline(headline, toParent: oldParent, childIndex: oldChildIndex)
			delegate?.applyChangesRestoringCursor(changes)
		}
		registerRedo()
	}
	
}

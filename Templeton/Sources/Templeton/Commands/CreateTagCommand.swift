//
//  CreateTagCommand.swift
//  
//
//  Created by Maurice Parker on 2/1/21.
//

import Foundation
import RSCore

public final class CreateTagCommand: OutlineCommand {
	public var undoActionName: String
	public var redoActionName: String
	public var undoManager: UndoManager
	public weak var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	
	public var newCursorIndex: Int?

	var outline: Outline
	var tagName: String
	var tag: Tag?
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, tagName: String) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.tagName = tagName
		undoActionName = L10n.addTag
		redoActionName = L10n.addTag
	}
	
	public func perform() {
		guard let tag = outline.account?.createTag(name: tagName) else { return }
		self.tag = tag
		outline.createTag(tag)
		registerUndo()
	}
	
	public func undo() {
		guard let tag = tag else { return }
		outline.deleteTag(tag)
		outline.account?.deleteTag(tag)
		registerRedo()
	}
	
}


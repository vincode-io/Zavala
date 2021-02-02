//
//  File.swift
//  
//
//  Created by Maurice Parker on 2/1/21.
//

import Foundation
import RSCore

public final class DeleteTagCommand: OutlineCommand {
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
		undoActionName = L10n.deleteTag
		redoActionName = L10n.deleteTag
	}
	
	public func perform() {
		guard let tag = outline.account?.findTag(tagID: tagName) else { return }
		self.tag = tag
		outline.removeTag(tag)
		outline.account?.deleteTag(tag)
		registerUndo()
	}
	
	public func undo() {
		guard let tag = tag else { return }
		outline.account?.createTag(tag)
		outline.addTag(tag)
		registerRedo()
	}
	
}

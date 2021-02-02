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
	var tag: Tag
	
	public init(undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, tag: Tag) {
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.tag = tag
		undoActionName = L10n.deleteTag
		redoActionName = L10n.deleteTag
	}
	
	public func perform() {
		outline.removeTag(tag)
		outline.account?.deleteTag(tag)
		registerUndo()
	}
	
	public func undo() {
		outline.account?.createTag(tag)
		outline.addTag(tag)
		registerRedo()
	}
	
}

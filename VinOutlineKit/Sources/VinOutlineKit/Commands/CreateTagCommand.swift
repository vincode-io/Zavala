//
//  CreateTagCommand.swift
//  
//
//  Created by Maurice Parker on 2/1/21.
//

import Foundation

public final class CreateTagCommand: OutlineCommand {
	
	var tagName: String
	var tag: Tag?
	
	public init(actionName: String, undoManager: UndoManager, delegate: OutlineCommandDelegate, outline: Outline, tagName: String) {
		self.tagName = tagName

		super.init(actionName: actionName, undoManager: undoManager, delegate: delegate, outline: outline)
	}
	
	public override func perform() {
		guard let tag = outline.account?.createTag(name: tagName) else { return }
		self.tag = tag
		outline.createTag(tag)
		registerUndo()
	}
	
	public override func undo() {
		guard let tag else { return }
		outline.deleteTag(tag)
		outline.account?.deleteTag(tag)
		registerRedo()
	}
	
}


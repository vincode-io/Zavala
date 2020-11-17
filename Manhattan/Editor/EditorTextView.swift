//
//  EditorTextView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

protocol EditorTextViewDelegate: class {
	func newHeadline(_: EditorTextView)
	func indent(_: EditorTextView)
	func outdent(_: EditorTextView)
	func moveUp(_: EditorTextView)
	func moveDown(_: EditorTextView)
}

class EditorTextView: UITextView {
	
	weak var editorDelegate: EditorTextViewDelegate?
	
	override var keyCommands: [UIKeyCommand]? {
		[
			UIKeyCommand(action: #selector(upArrowPressed(_:)), input: UIKeyCommand.inputUpArrow),
			UIKeyCommand(action: #selector(downArrowPressed(_:)), input: UIKeyCommand.inputDownArrow),
			UIKeyCommand(action: #selector(returnPressed(_:)), input: "\r"),
			UIKeyCommand(action: #selector(tabPressed(_:)), input: "\t"),
			UIKeyCommand(input: "\t", modifierFlags: [.shift], action: #selector(shiftTabPressed(_:)))
		]
	}

	@objc func returnPressed(_ sender: Any) {
		editorDelegate?.newHeadline(self)
	}
	
	@objc func tabPressed(_ sender: Any) {
		editorDelegate?.indent(self)
	}
	
	@objc func shiftTabPressed(_ sender: Any) {
		editorDelegate?.outdent(self)
	}
	
	@objc func upArrowPressed(_ sender: Any) {
		editorDelegate?.moveUp(self)
	}
	
	@objc func downArrowPressed(_ sender: Any) {
		editorDelegate?.moveDown(self)
	}
	
}

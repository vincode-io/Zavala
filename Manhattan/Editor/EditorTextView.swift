//
//  EditorTextView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

protocol EditorTextViewDelegate: class {
	var item: EditorItem? { get }
	func deleteHeadline(_: EditorTextView)
	func createHeadline(_: EditorTextView)
	func indent(_: EditorTextView, attributedText: NSAttributedString)
	func outdent(_: EditorTextView, attributedText: NSAttributedString)
	func moveUp(_: EditorTextView)
	func moveDown(_: EditorTextView)
}

class EditorTextView: UITextView, TextCursorSource {
	
	weak var editorDelegate: EditorTextViewDelegate?
	
	var identifier: Any? {
		return editorDelegate?.item
	}

	override var keyCommands: [UIKeyCommand]? {
		let keys = [
			UIKeyCommand(action: #selector(upArrowPressed(_:)), input: UIKeyCommand.inputUpArrow),
			UIKeyCommand(action: #selector(downArrowPressed(_:)), input: UIKeyCommand.inputDownArrow),
			UIKeyCommand(action: #selector(tabPressed(_:)), input: "\t"),
			UIKeyCommand(input: "\t", modifierFlags: [.shift], action: #selector(shiftTabPressed(_:)))
		]
		return keys
	}

	override func deleteBackward() {
		super.deleteBackward()
		if attributedText.length == 0 {
			editorDelegate?.deleteHeadline(self)
		}
	}
	
	@objc func tabPressed(_ sender: Any) {
		editorDelegate?.indent(self, attributedText: attributedText)
	}
	
	@objc func shiftTabPressed(_ sender: Any) {
		editorDelegate?.outdent(self, attributedText: attributedText)
	}
	
	@objc func upArrowPressed(_ sender: Any) {
		editorDelegate?.moveUp(self)
	}
	
	@objc func downArrowPressed(_ sender: Any) {
		editorDelegate?.moveDown(self)
	}
	
}

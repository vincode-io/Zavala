//
//  EditorTextView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

protocol EditorTextViewDelegate: class {
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
			UIKeyCommand(action: #selector(downArrowPressed(_:)), input: UIKeyCommand.inputPageDown),
			UIKeyCommand(action: #selector(tabPressed(_:)), input: "\t"),
			UIKeyCommand(input: "\t", modifierFlags: [.shift], action: #selector(shiftTabPressed(_:)))
		]
	}

	@IBAction func tabPressed(_ sender: Any) {
		editorDelegate?.indent(self)
	}
	
	@IBAction func shiftTabPressed(_ sender: Any) {
		editorDelegate?.outdent(self)
	}
	
	@IBAction func upArrowPressed(_ sender: Any) {
		editorDelegate?.moveUp(self)
	}
	
	@IBAction func downArrowPressed(_ sender: Any) {
		editorDelegate?.moveDown(self)
	}
	
}

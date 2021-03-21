//
//  EnhancedSearchTextField.swift
//  Zavala
//
//  Created by Maurice Parker on 3/21/21.
//

import UIKit

open class EnhancedSearchTextField: UISearchTextField {

	open override var keyCommands: [UIKeyCommand]? {
		[
			UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .shift, action: #selector(shiftUpArrow(_:))),
			UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .shift, action: #selector(shiftDownArrow(_:)))
		]
	}
	
	@objc func shiftUpArrow(_ sender: Any) {
		if let cursor = selectedTextRange?.start {
			selectedTextRange = textRange(from: beginningOfDocument, to: cursor)
		}
	}

	@objc func shiftDownArrow(_ sender: Any) {
		if let cursor = selectedTextRange?.start {
			selectedTextRange = textRange(from: cursor, to: endOfDocument)
		}
	}
}

//
//  EditorTextView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

protocol EditorTextViewDelegate: class {
	var undoManager: UndoManager? { get }
	var currentKeyPresses: Set<UIKeyboardHIDUsage> { get }
	func deleteHeadline(_: Headline)
	func createHeadline(_: Headline)
	func indentHeadline(_: Headline, attributedText: NSAttributedString)
	func outdentHeadline(_: Headline, attributedText: NSAttributedString)
	func moveCursorUp(headline: Headline)
	func moveCursorDown(headline: Headline)
}

class EditorTextView: UITextView {
	
	override var undoManager: UndoManager? {
		guard let textViewUndoManager = super.undoManager, let controllerUndoManager = editorDelegate?.undoManager else { return nil }
		if stackedUndoManager == nil {
			stackedUndoManager = StackedUndoManger(mainUndoManager: textViewUndoManager, fallBackUndoManager: controllerUndoManager)
		}
		return stackedUndoManager
	}
	
	weak var editorDelegate: EditorTextViewDelegate?
	weak var headline: Headline?

	override var keyCommands: [UIKeyCommand]? {
		let keys = [
			UIKeyCommand(action: #selector(tabPressed(_:)), input: "\t"),
			UIKeyCommand(input: "\t", modifierFlags: [.shift], action: #selector(shiftTabPressed(_:)))
		]
		return keys
	}
	
	override var intrinsicContentSize: CGSize {
		// We have to add one to the intrinsic content width or the cursor won't show
		var size = super.intrinsicContentSize
		size.width = size.width + 1
		return size
	}
	
	private var stackedUndoManager: UndoManager?
	
	@discardableResult
	override func becomeFirstResponder() -> Bool {
		let result = super.becomeFirstResponder()
		guard let headline = headline else { return result }

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			if self.editorDelegate?.currentKeyPresses.contains(.keyboardUpArrow) ?? false {
				self.editorDelegate?.moveCursorUp(headline: headline)
			}
			if self.editorDelegate?.currentKeyPresses.contains(.keyboardDownArrow) ?? false {
				self.editorDelegate?.moveCursorDown(headline: headline)
			}
		}
		
		return result
	}

	override func deleteBackward() {
		guard let headline = headline else { return }
		if attributedText.length == 0 {
			editorDelegate?.deleteHeadline(headline)
		} else {
			super.deleteBackward()
		}
	}
	
	@objc func tabPressed(_ sender: Any) {
		guard let headline = headline else { return }
		editorDelegate?.indentHeadline(headline, attributedText: attributedText)
	}
	
	@objc func shiftTabPressed(_ sender: Any) {
		guard let headline = headline else { return }
		editorDelegate?.outdentHeadline(headline, attributedText: attributedText)
	}
	
	var isSelecting: Bool {
		return !(selectedTextRange?.isEmpty ?? true)
	}
	
}

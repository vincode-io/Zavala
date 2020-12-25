//
//  EditorTextRowNoteTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/13/20.
//

import UIKit
import Templeton

protocol EditorTextRowNoteTextViewDelegate: class {
	var editorRowNoteTextViewUndoManager: UndoManager? { get }
	var editorRowNoteTextViewTextRowStrings: TextRowStrings { get }
	func invalidateLayout(_ : EditorTextRowNoteTextView)
	func textChanged(_ : EditorTextRowNoteTextView, row: TextRow, isInNotes: Bool, cursorPosition: Int)
	func deleteRowNote(_ : EditorTextRowNoteTextView, row: TextRow)
	func moveCursorTo(_ : EditorTextRowNoteTextView, row: TextRow)
	func moveCursorDown(_ : EditorTextRowNoteTextView, row: TextRow)
	func editLink(_: EditorTextRowNoteTextView, _ link: String?, range: NSRange)
}

class EditorTextRowNoteTextView: OutlineTextView {
	
	override var editorUndoManager: UndoManager? {
		return editorDelegate?.editorRowNoteTextViewUndoManager
	}
	
	override var keyCommands: [UIKeyCommand]? {
		var keys = [UIKeyCommand]()
		if cursorPosition == 0 {
			keys.append(UIKeyCommand(action: #selector(moveCursorToText(_:)), input: UIKeyCommand.inputUpArrow))
		}
		if cursorPosition == attributedText.length {
			keys.append(UIKeyCommand(action: #selector(moveCursorDown(_:)), input: UIKeyCommand.inputDownArrow))
		}
		keys.append(UIKeyCommand(action: #selector(moveCursorToText(_:)), input: UIKeyCommand.inputEscape))
		keys.append(toggleBoldCommand)
		keys.append(toggleItalicsCommand)
		keys.append(editLinkCommand)
		return keys
	}
	
	weak var editorDelegate: EditorTextRowNoteTextViewDelegate?
	
	override var textRowStrings: TextRowStrings? {
		return editorDelegate?.editorRowNoteTextViewTextRowStrings
	}
	
	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		
		self.delegate = self

		self.font = OutlineFont.note
		self.textColor = .secondaryLabel
		self.linkTextAttributes = [.foregroundColor: UIColor.secondaryLabel, .underlineStyle: 1]
	}
	
	private var textViewHeight: CGFloat?
	private var isTextChanged = false
	private var isSavingTextUnnecessary = false

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
			textStorage.replaceFont(with: OutlineFont.note)
		}
	}
	
	override func resignFirstResponder() -> Bool {
		if let row = textRow {
			CursorCoordinates.lastKnownCoordinates = CursorCoordinates(row: row, isInNotes: false, cursorPosition: lastCursorPosition)
		}
		return super.resignFirstResponder()
	}

	override func deleteBackward() {
		guard let textRow = textRow else { return }
		if attributedText.length == 0 {
			isSavingTextUnnecessary = true
			editorDelegate?.deleteRowNote(self, row: textRow)
		} else {
			super.deleteBackward()
		}
	}

	@objc func moveCursorToText(_ sender: Any) {
		guard let textRow = textRow else { return }
		editorDelegate?.moveCursorTo(self, row: textRow)
	}
	
	@objc func moveCursorDown(_ sender: Any) {
		guard let textRow = textRow else { return }
		editorDelegate?.moveCursorDown(self, row: textRow)
	}

	@objc override func editLink(_ sender: Any?) {
		let result = findAndSelectLink()
		editorDelegate?.editLink(self, result.0, range: result.1)
	}
	
	override func updateLinkForCurrentSelection(link: String?, range: NSRange) {
		super.updateLinkForCurrentSelection(link: link, range: range)
		isTextChanged = true
	}
	
}

// MARK: UITextViewDelegate

extension EditorTextRowNoteTextView: UITextViewDelegate {
	
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		textViewHeight = fittingSize.height
		return true
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		guard isTextChanged, let textRow = textRow else { return }
		
		if isSavingTextUnnecessary {
			isSavingTextUnnecessary = false
		} else {
			editorDelegate?.textChanged(self, row: textRow, isInNotes: true, cursorPosition: lastCursorPosition)
		}
		
		isTextChanged = false
	}
	
	func textViewDidChange(_ textView: UITextView) {
		isTextChanged = true
		lastCursorPosition = cursorPosition

		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		if textViewHeight != fittingSize.height {
			textViewHeight = fittingSize.height
			editorDelegate?.invalidateLayout(self)
		}
	}
	
}

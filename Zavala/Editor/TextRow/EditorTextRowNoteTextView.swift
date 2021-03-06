//
//  EditorTextRowNoteTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/13/20.
//

import UIKit
import Templeton

protocol EditorTextRowNoteTextViewDelegate: AnyObject {
	var editorRowNoteTextViewUndoManager: UndoManager? { get }
	var editorRowNoteTextViewTextRowStrings: TextRowStrings { get }
	func invalidateLayout(_ : EditorTextRowNoteTextView)
	func didBecomeActive(_ : EditorTextRowNoteTextView)
	func textChanged(_ : EditorTextRowNoteTextView, row: Row, isInNotes: Bool, cursorPosition: Int)
	func deleteRowNote(_ : EditorTextRowNoteTextView, row: Row)
	func moveCursorTo(_ : EditorTextRowNoteTextView, row: Row)
	func moveCursorDown(_ : EditorTextRowNoteTextView, row: Row)
	func editLink(_: EditorTextRowNoteTextView, _ link: String?, text: String?, range: NSRange)
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
	
	private var autosaveWorkItem: DispatchWorkItem?
	private var textViewHeight: CGFloat?
	private var isSavingTextUnnecessary = false

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		
		self.delegate = self

		self.font = OutlineFont.note
		self.textColor = .secondaryLabel
		self.linkTextAttributes = [.foregroundColor: UIColor.secondaryLabel, .underlineStyle: 1]
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
			textStorage.replaceFont(with: OutlineFont.note)
		}
	}

	@discardableResult
	override func becomeFirstResponder() -> Bool {
		let result = super.becomeFirstResponder()
		editorDelegate?.didBecomeActive(self)
		return result
	}
	
	override func resignFirstResponder() -> Bool {
		if let row = row {
			CursorCoordinates.lastKnownCoordinates = CursorCoordinates(row: row, isInNotes: false, cursorPosition: cursorPosition)
		}
		return super.resignFirstResponder()
	}

	override func deleteBackward() {
		guard let textRow = row else { return }
		if attributedText.length == 0 {
			isSavingTextUnnecessary = true
			editorDelegate?.deleteRowNote(self, row: textRow)
		} else {
			super.deleteBackward()
		}
	}

	@objc func moveCursorToText(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.moveCursorTo(self, row: textRow)
	}
	
	@objc func moveCursorDown(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.moveCursorDown(self, row: textRow)
	}

	@objc override func editLink(_ sender: Any?) {
		let result = findAndSelectLink()
		editorDelegate?.editLink(self, result.0, text: result.1, range: result.2)
	}
	
	override func saveText() {
		guard isTextChanged, let textRow = row else { return }
		
		if isSavingTextUnnecessary {
			isSavingTextUnnecessary = false
		} else {
			editorDelegate?.textChanged(self, row: textRow, isInNotes: true, cursorPosition: cursorPosition)
		}
		
		autosaveWorkItem?.cancel()
		isTextChanged = false
	}
	
	override func updateLinkForCurrentSelection(text: String, link: String?, range: NSRange) {
		super.updateLinkForCurrentSelection(text: text, link: link, range: range)
		textStorage.replaceFont(with: OutlineFont.note)
		isTextChanged = true
		saveText()
	}
	
}

// MARK: CursorCoordinatesProvider

extension EditorTextRowNoteTextView: CursorCoordinatesProvider {

	var coordinates: CursorCoordinates? {
		if let row = row {
			return CursorCoordinates(row: row, isInNotes: true, cursorPosition: cursorPosition)
		}
		return nil
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
		detectData()
		saveText()
	}
	
	func textViewDidChange(_ textView: UITextView) {
		isTextChanged = true

		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		if textViewHeight != fittingSize.height {
			textViewHeight = fittingSize.height
			editorDelegate?.invalidateLayout(self)
		}

		autosaveWorkItem?.cancel()
		autosaveWorkItem = DispatchWorkItem { [weak self] in
			self?.saveText()
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: autosaveWorkItem!)
	}
	
}

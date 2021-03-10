//
//  EditorTextRowTopicTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

protocol EditorTextRowTopicTextViewDelegate: AnyObject {
	var editorRowTopicTextViewUndoManager: UndoManager? { get }
	var editorRowTopicTextViewTextRowStrings: TextRowStrings { get }
	func didBecomeActive(_: EditorTextRowTopicTextView)
	func invalidateLayout(_: EditorTextRowTopicTextView)
	func textChanged(_: EditorTextRowTopicTextView, row: Row, isInNotes: Bool, cursorPosition: Int)
	func deleteRow(_: EditorTextRowTopicTextView, row: Row)
	func createRow(_: EditorTextRowTopicTextView, beforeRow: Row)
	func createRow(_: EditorTextRowTopicTextView, afterRow: Row)
	func indentRow(_: EditorTextRowTopicTextView, row: Row)
	func outdentRow(_: EditorTextRowTopicTextView, row: Row)
	func splitRow(_: EditorTextRowTopicTextView, row: Row, topic: NSAttributedString, cursorPosition: Int)
	func createRowNote(_: EditorTextRowTopicTextView, row: Row)
	func editLink(_: EditorTextRowTopicTextView, _ link: String?, range: NSRange)
}

class EditorTextRowTopicTextView: OutlineTextView {
	
	override var editorUndoManager: UndoManager? {
		return editorDelegate?.editorRowTopicTextViewUndoManager
	}
	
	override var keyCommands: [UIKeyCommand]? {
		let keys = [
			UIKeyCommand(action: #selector(indent(_:)), input: "\t"),
			UIKeyCommand(input: "\t", modifierFlags: [.shift], action: #selector(outdent(_:))),
			UIKeyCommand(input: "\t", modifierFlags: [.alternate], action: #selector(insertTab(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.alternate], action: #selector(insertReturn(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift], action: #selector(insertRow(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift, .alternate], action: #selector(split(_:))),
			UIKeyCommand(input: "-", modifierFlags: [.control], action: #selector(addNote(_:))),
			toggleBoldCommand,
			toggleItalicsCommand,
			editLinkCommand
		]
		return keys
	}
	
	weak var editorDelegate: EditorTextRowTopicTextViewDelegate?
	
	override var textRowStrings: TextRowStrings? {
		return editorDelegate?.editorRowTopicTextViewTextRowStrings
	}
	
	private var autosaveWorkItem: DispatchWorkItem?
	private var textViewHeight: CGFloat?
	private var isSavingTextUnnecessary = false

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)

		self.delegate = self

		self.font = OutlineFont.topic
		self.linkTextAttributes = [.foregroundColor: UIColor.label, .underlineStyle: 1]
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
			textStorage.replaceFont(with: OutlineFont.topic)
		}
	}
	
	@discardableResult
	override func becomeFirstResponder() -> Bool {
		editorDelegate?.didBecomeActive(self)
		// We leave and empty string in text field to help with autolayout where first baseline is used
		if textStorage.length == 1 && textStorage.string.starts(with: " ") {
			textStorage.deleteCharacters(in: NSRange(location: 0, length: 1))
		}
		return super.becomeFirstResponder()
	}
	
	override func resignFirstResponder() -> Bool {
		if let textRow = row {
			CursorCoordinates.lastKnownCoordinates = CursorCoordinates(row: textRow, isInNotes: false, cursorPosition: lastCursorPosition)
		}
		return super.resignFirstResponder()
	}

	override func deleteBackward() {
		guard let textRow = row else { return }
		if attributedText.length == 0 && textRow.rowCount == 0 {
			editorDelegate?.deleteRow(self, row: textRow)
		} else {
			super.deleteBackward()
		}
	}

	@objc func indent(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.indentRow(self, row: textRow)
	}
	
	@objc func outdent(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.outdentRow(self, row: textRow)
	}
	
	@objc func insertTab(_ sender: Any) {
		insertText("\t")
	}
	
	@objc func insertReturn(_ sender: Any) {
		insertText("\n")
	}
	
	@objc func insertRow(_ sender: Any) {
		guard let textRow = row else { return }
		isSavingTextUnnecessary = true
		editorDelegate?.createRow(self, beforeRow: textRow)
	}
	
	@objc func addNote(_ sender: Any) {
		guard let textRow = row else { return }
		isSavingTextUnnecessary = true
		editorDelegate?.createRowNote(self, row: textRow)
	}
	
	@objc func split(_ sender: Any) {
		guard let textRow = row else { return }
		
		isSavingTextUnnecessary = true
		
		if cursorPosition == 0 {
			editorDelegate?.createRow(self, beforeRow: textRow)
		} else {
			editorDelegate?.splitRow(self, row: textRow, topic: attributedText, cursorPosition: cursorPosition)
		}
	}
	
	@objc override func editLink(_ sender: Any?) {
		let result = findAndSelectLink()
		editorDelegate?.editLink(self, result.0, range: result.1)
	}
	
	override func saveText() {
		guard isTextChanged, let textRow = row else { return }
		
		if isSavingTextUnnecessary {
			isSavingTextUnnecessary = false
		} else {
			editorDelegate?.textChanged(self, row: textRow, isInNotes: false, cursorPosition: lastCursorPosition)
		}
		
		isTextChanged = false
	}
	
	override func updateLinkForCurrentSelection(link: String?, range: NSRange) {
		super.updateLinkForCurrentSelection(link: link, range: range)
		isTextChanged = true
		saveText()
	}
	
}

// MARK: CursorCoordinatesProvider

extension EditorTextRowTopicTextView: CursorCoordinatesProvider {

	var coordinates: CursorCoordinates? {
		if let row = row {
			return CursorCoordinates(row: row, isInNotes: false, cursorPosition: cursorPosition)
		}
		return nil
	}

}

// MARK: UITextViewDelegate

extension EditorTextRowTopicTextView: UITextViewDelegate {
	
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		textViewHeight = fittingSize.height
		return true
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		detectData()
		saveText()
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		guard let textRow = row else { return true }
		switch text {
		case "\n":
			editorDelegate?.createRow(self, afterRow: textRow)
			return false
		default:
			return true
		}
	}
	
	func textViewDidChange(_ textView: UITextView) {
		isTextChanged = true
		lastCursorPosition = cursorPosition

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

//
//  EditorHeadlineTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

protocol EditorHeadlineTextViewDelegate: class {
	var editorHeadlineTextViewUndoManager: UndoManager? { get }
	var editorHeadlineTextViewTextRowStrings: TextRowStrings { get }
	func invalidateLayout(_: EditorHeadlineTextView)
	func textChanged(_: EditorHeadlineTextView, headline: TextRow, isInNotes: Bool, cursorPosition: Int)
	func deleteHeadline(_: EditorHeadlineTextView, headline: TextRow)
	func createHeadline(_: EditorHeadlineTextView, beforeHeadline: TextRow)
	func createHeadline(_: EditorHeadlineTextView, afterHeadline: TextRow)
	func indentHeadline(_: EditorHeadlineTextView, headline: TextRow)
	func outdentHeadline(_: EditorHeadlineTextView, headline: TextRow)
	func splitHeadline(_: EditorHeadlineTextView, headline: TextRow, topic: NSAttributedString, cursorPosition: Int)
	func createHeadlineNote(_: EditorHeadlineTextView, headline: TextRow)
	func editLink(_: EditorHeadlineTextView, _ link: String?, range: NSRange)
}

class EditorHeadlineTextView: OutlineTextView {
	
	override var editorUndoManager: UndoManager? {
		return editorDelegate?.editorHeadlineTextViewUndoManager
	}
	
	override var keyCommands: [UIKeyCommand]? {
		let keys = [
			UIKeyCommand(action: #selector(indent(_:)), input: "\t"),
			UIKeyCommand(input: "\t", modifierFlags: [.shift], action: #selector(outdent(_:))),
			UIKeyCommand(input: "\t", modifierFlags: [.alternate], action: #selector(insertTab(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.alternate], action: #selector(insertReturn(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift], action: #selector(addNote(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift, .alternate], action: #selector(split(_:))),
			toggleBoldCommand,
			toggleItalicsCommand,
			editLinkCommand
		]
		return keys
	}
	
	weak var editorDelegate: EditorHeadlineTextViewDelegate?
	
	override var textRowStrings: TextRowStrings? {
		return editorDelegate?.editorHeadlineTextViewTextRowStrings
	}
	
	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)

		self.delegate = self

		self.font = HeadlineFont.text
		self.linkTextAttributes = [.foregroundColor: UIColor.label, .underlineStyle: 1]
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
			textStorage.replaceFont(with: HeadlineFont.text)
		}
	}
	
	override func resignFirstResponder() -> Bool {
		if let headline = headline {
			CursorCoordinates.lastKnownCoordinates = CursorCoordinates(row: headline, isInNotes: false, cursorPosition: lastCursorPosition)
		}
		return super.resignFirstResponder()
	}

	override func deleteBackward() {
		guard let headline = headline else { return }
		if attributedText.length == 0 {
			editorDelegate?.deleteHeadline(self, headline: headline)
		} else {
			super.deleteBackward()
		}
	}

	@objc func indent(_ sender: Any) {
		guard let headline = headline else { return }
		editorDelegate?.indentHeadline(self, headline: headline)
	}
	
	@objc func outdent(_ sender: Any) {
		guard let headline = headline else { return }
		editorDelegate?.outdentHeadline(self, headline: headline)
	}
	
	@objc func insertTab(_ sender: Any) {
		insertText("\t")
	}
	
	@objc func insertReturn(_ sender: Any) {
		insertText("\n")
	}
	
	@objc func addNote(_ sender: Any) {
		guard let headline = headline else { return }
		isSavingTextUnnecessary = true
		editorDelegate?.createHeadlineNote(self, headline: headline)
	}
	
	@objc func split(_ sender: Any) {
		guard let headline = headline else { return }
		
		isSavingTextUnnecessary = true
		
		if cursorPosition == 0 {
			editorDelegate?.createHeadline(self, beforeHeadline: headline)
		} else {
			editorDelegate?.splitHeadline(self, headline: headline, topic: attributedText, cursorPosition: cursorPosition)
		}
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

extension EditorHeadlineTextView: UITextViewDelegate {
	
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		textViewHeight = fittingSize.height
		return true
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		guard isTextChanged, let headline = headline else { return }
		
		if isSavingTextUnnecessary {
			isSavingTextUnnecessary = false
		} else {
			editorDelegate?.textChanged(self, headline: headline, isInNotes: false, cursorPosition: lastCursorPosition)
		}
		
		isTextChanged = false
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		guard let headline = headline else { return true }
		switch text {
		case "\n":
			editorDelegate?.createHeadline(self, afterHeadline: headline)
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
	}
	
}

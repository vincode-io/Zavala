//
//  EditorHeadlineTextView.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

protocol EditorHeadlineTextViewDelegate: class {
	var editorHeadlineTextViewUndoManager: UndoManager? { get }
	var editorHeadlineTextViewAttibutedTexts: HeadlineTexts { get }
	func invalidateLayout(_: EditorHeadlineTextView)
	func textChanged(_: EditorHeadlineTextView, headline: Headline, isInNotes: Bool, cursorPosition: Int)
	func deleteHeadline(_: EditorHeadlineTextView, headline: Headline)
	func createHeadline(_: EditorHeadlineTextView, beforeHeadline: Headline)
	func createHeadline(_: EditorHeadlineTextView, afterHeadline: Headline)
	func indentHeadline(_: EditorHeadlineTextView, headline: Headline)
	func outdentHeadline(_: EditorHeadlineTextView, headline: Headline)
	func splitHeadline(_: EditorHeadlineTextView, headline: Headline, attributedText: NSAttributedString, cursorPosition: Int)
	func createHeadlineNote(_: EditorHeadlineTextView, headline: Headline)
	func editLink(_: EditorHeadlineTextView, _ link: String?)
}

class EditorHeadlineTextView: OutlineTextView {
	
	override var editorUndoManager: UndoManager? {
		return editorDelegate?.editorHeadlineTextViewUndoManager
	}
	
	override var keyCommands: [UIKeyCommand]? {
		let keys = [
			UIKeyCommand(action: #selector(tabPressed(_:)), input: "\t"),
			UIKeyCommand(input: "\t", modifierFlags: [.shift], action: #selector(shiftTabPressed(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.alternate], action: #selector(optionReturnPressed(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift], action: #selector(shiftReturnPressed(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift, .alternate], action: #selector(shiftOptionReturnPressed(_:))),
			toggleBoldCommand,
			toggleItalicsCommand,
			editLinkCommand
		]
		return keys
	}
	
	weak var editorDelegate: EditorHeadlineTextViewDelegate?
	
	override var attributedTexts: HeadlineTexts? {
		return editorDelegate?.editorHeadlineTextViewAttibutedTexts
	}
	
	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)

		self.delegate = self

		if traitCollection.userInterfaceIdiom == .mac {
			let bodyFont = UIFont.preferredFont(forTextStyle: .body)
			self.font = bodyFont.withSize(bodyFont.pointSize + 1)
		} else {
			self.font = UIFont.preferredFont(forTextStyle: .body)
		}
		
		self.linkTextAttributes = [.foregroundColor: UIColor.label, .underlineStyle: 1]
	}
	
	private var textViewHeight: CGFloat?
	private var isTextChanged = false
	private var isSavingTextUnnecessary = false

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func deleteBackward() {
		guard let headline = headline else { return }
		if attributedText.length == 0 {
			editorDelegate?.deleteHeadline(self, headline: headline)
		} else {
			super.deleteBackward()
		}
	}

	@objc func tabPressed(_ sender: Any) {
		guard let headline = headline else { return }
		editorDelegate?.indentHeadline(self, headline: headline)
	}
	
	@objc func shiftTabPressed(_ sender: Any) {
		guard let headline = headline else { return }
		editorDelegate?.outdentHeadline(self, headline: headline)
	}
	
	@objc func optionReturnPressed(_ sender: Any) {
		insertText("\n")
	}
	
	@objc func shiftReturnPressed(_ sender: Any) {
		guard let headline = headline else { return }
		isSavingTextUnnecessary = true
		editorDelegate?.createHeadlineNote(self, headline: headline)
	}
	
	@objc func shiftOptionReturnPressed(_ sender: Any) {
		guard let headline = headline else { return }
		
		isSavingTextUnnecessary = true
		
		if cursorPosition == 0 {
			editorDelegate?.createHeadline(self, beforeHeadline: headline)
		} else {
			editorDelegate?.splitHeadline(self, headline: headline, attributedText: attributedText, cursorPosition: cursorPosition)
		}
	}
	
	@objc override func editLink(_ sender: Any?) {
		let link = findAndSelectLink()
		editorDelegate?.editLink(self, link)
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

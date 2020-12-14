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
	func textChanged(_: EditorHeadlineTextView, headline: Headline)
	func deleteHeadline(_: EditorHeadlineTextView, headline: Headline)
	func createHeadline(_: EditorHeadlineTextView, afterHeadline: Headline)
	func indentHeadline(_: EditorHeadlineTextView, headline: Headline)
	func outdentHeadline(_: EditorHeadlineTextView, headline: Headline)
	func splitHeadline(_: EditorHeadlineTextView, headline: Headline, attributedText: NSAttributedString, cursorPosition: Int)
	func createHeadlineNote(_: EditorHeadlineTextView, headline: Headline)
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
			UIKeyCommand(input: "\r", modifierFlags: [.shift, .alternate], action: #selector(shiftOptionReturnPressed(_:)))
		]
		return keys
	}
	
	weak var editorDelegate: EditorHeadlineTextViewDelegate?
	
	override var attributedTexts: HeadlineTexts? {
		return editorDelegate?.editorHeadlineTextViewAttibutedTexts
	}
	
	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)

		// These gesture recognizers will conflict with context menu preview dragging if not removed.
		if traitCollection.userInterfaceIdiom != .mac {
			gestureRecognizers?.forEach {
				if $0.name == "dragInitiation"
					|| $0.name == "dragExclusionRelationships"
					|| $0.name == "dragFailureRelationships"
					|| $0.name == "com.apple.UIKit.longPressClickDriverPrimary" {
					removeGestureRecognizer($0)
				}
			}
		}
		
		self.delegate = self
		self.isScrollEnabled = false
		self.textContainer.lineFragmentPadding = 0
		self.textContainerInset = .zero

		if traitCollection.userInterfaceIdiom == .mac {
			let bodyFont = UIFont.preferredFont(forTextStyle: .body)
			self.font = bodyFont.withSize(bodyFont.pointSize + 1)
		} else {
			self.font = UIFont.preferredFont(forTextStyle: .body)
		}

		self.backgroundColor = .clear
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
		editorDelegate?.splitHeadline(self, headline: headline, attributedText: attributedText, cursorPosition: cursorPosition)
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
			editorDelegate?.textChanged(self, headline: headline)
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
			isTextChanged = true
			return true
		}
	}
	
	func textViewDidChange(_ textView: UITextView) {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		if textViewHeight != fittingSize.height {
			textViewHeight = fittingSize.height
			editorDelegate?.invalidateLayout(self)
		}
	}
	
}

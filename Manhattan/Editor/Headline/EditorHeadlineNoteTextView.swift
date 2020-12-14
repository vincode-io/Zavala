//
//  EditorHeadlineNoteTextView.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/13/20.
//

import UIKit
import Templeton

protocol EditorHeadlineNoteTextViewDelegate: class {
	var editorHeadlineNoteTextViewUndoManager: UndoManager? { get }
	var editorHeadlineNoteTextViewAttibutedTexts: HeadlineTexts { get }
	func invalidateLayout(_ : EditorHeadlineNoteTextView)
	func textChanged(_ : EditorHeadlineNoteTextView, headline: Headline)
	func deleteHeadlineNote(_ : EditorHeadlineNoteTextView, headline: Headline)
}

class EditorHeadlineNoteTextView: OutlineTextView {
	
	override var editorUndoManager: UndoManager? {
		return editorDelegate?.editorHeadlineNoteTextViewUndoManager
	}
	
	weak var editorDelegate: EditorHeadlineNoteTextViewDelegate?
	
	override var attributedTexts: HeadlineTexts? {
		return editorDelegate?.editorHeadlineNoteTextViewAttibutedTexts
	}
	
	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		
		self.delegate = self
		self.isScrollEnabled = false
		self.textContainer.lineFragmentPadding = 0
		self.textContainerInset = .zero

		if traitCollection.userInterfaceIdiom == .mac {
			self.font = UIFont.preferredFont(forTextStyle: .body)
		} else {
			let bodyFont = UIFont.preferredFont(forTextStyle: .body)
			self.font = bodyFont.withSize(bodyFont.pointSize - 1)
		}

		self.textColor = .secondaryLabel
		
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
			isSavingTextUnnecessary = true
			editorDelegate?.deleteHeadlineNote(self, headline: headline)
		} else {
			super.deleteBackward()
		}
	}

}

// MARK: UITextViewDelegate

extension EditorHeadlineNoteTextView: UITextViewDelegate {
	
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
		isTextChanged = true
		return true
	}
	
	func textViewDidChange(_ textView: UITextView) {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		if textViewHeight != fittingSize.height {
			textViewHeight = fittingSize.height
			editorDelegate?.invalidateLayout(self)
		}
	}
	
}

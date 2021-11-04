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
	var editorRowTopicTextViewInputAccessoryView: UIView? { get }
	func didBecomeActive(_: EditorTextRowTopicTextView, row: Row)
	func invalidateLayout(_: EditorTextRowTopicTextView)
	func makeCursorVisibleIfNecessary(_: EditorTextRowTopicTextView)
	func textChanged(_: EditorTextRowTopicTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings)
	func deleteRow(_: EditorTextRowTopicTextView, row: Row, rowStrings: RowStrings)
	func createRow(_: EditorTextRowTopicTextView, beforeRow: Row)
	func createRow(_: EditorTextRowTopicTextView, afterRow: Row, rowStrings: RowStrings)
	func moveRowLeft(_: EditorTextRowTopicTextView, row: Row, rowStrings: RowStrings)
	func moveRowRight(_: EditorTextRowTopicTextView, row: Row, rowStrings: RowStrings)
	func splitRow(_: EditorTextRowTopicTextView, row: Row, topic: NSAttributedString, cursorPosition: Int)
	func editLink(_: EditorTextRowTopicTextView, _ link: String?, text: String?, range: NSRange)
}

class EditorTextRowTopicTextView: EditorTextRowTextView {
	
	override var editorUndoManager: UndoManager? {
		return editorDelegate?.editorRowTopicTextViewUndoManager
	}
	
	override var keyCommands: [UIKeyCommand]? {
		let shiftTab = UIKeyCommand(input: "\t", modifierFlags: [.shift], action: #selector(moveLeft(_:)))
		if #available(iOS 15.0, *) {
			shiftTab.wantsPriorityOverSystemBehavior = true
		}
		
		let keys = [
			shiftTab,
			UIKeyCommand(action: #selector(moveRight(_:)), input: "\t"),
			UIKeyCommand(input: "\t", modifierFlags: [.alternate], action: #selector(insertTab(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.alternate], action: #selector(insertReturn(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift], action: #selector(insertRow(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift, .alternate], action: #selector(split(_:))),
			toggleBoldCommand,
			toggleItalicsCommand,
			editLinkCommand
		]
		
		return keys
	}
	
	weak var editorDelegate: EditorTextRowTopicTextViewDelegate?
	
	override var rowStrings: RowStrings {
		return RowStrings.topic(cleansedAttributedText)
	}
	
	var cursorIsOnTopLine: Bool {
		guard let cursorRect = cursorRect else { return false }
		let lineStart = closestPosition(to: CGPoint(x: 0, y: cursorRect.midY))
		return lineStart == beginningOfDocument
	}
	
	var cursorIsOnBottomLine: Bool {
		guard let cursorRect = cursorRect else { return false }
		let lineEnd = closestPosition(to: CGPoint(x: bounds.maxX, y: cursorRect.midY))
		return lineEnd == endOfDocument
	}
	
	private var autosaveWorkItem: DispatchWorkItem?
	private var textViewHeight: CGFloat?
	private var isSavingTextUnnecessary = false

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		self.delegate = self
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@discardableResult
	override func becomeFirstResponder() -> Bool {
		inputAccessoryView = editorDelegate?.editorRowTopicTextViewInputAccessoryView
		let result = super.becomeFirstResponder()
		didBecomeActive()
		return result
	}
	
	override func resignFirstResponder() -> Bool {
		if let textRow = row {
			CursorCoordinates.lastKnownCoordinates = CursorCoordinates(row: textRow, isInNotes: false, selection: selectedRange)
		}
		return super.resignFirstResponder()
	}
	
	override func didBecomeActive() {
		if let row = row {
			editorDelegate?.didBecomeActive(self, row: row)
		}
	}

	override func invalidateLayout() {
		editorDelegate?.invalidateLayout(self)
	}
	
	override func deleteBackward() {
		guard let textRow = row else { return }
		if attributedText.length == 0 && textRow.rowCount == 0 {
			editorDelegate?.deleteRow(self, row: textRow, rowStrings: rowStrings)
		} else {
			super.deleteBackward()
		}
	}

	@objc func createRow(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.createRow(self, afterRow: textRow, rowStrings: rowStrings)
	}
	
	@objc func moveLeft(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.moveRowLeft(self, row: textRow, rowStrings: rowStrings)
	}
	
	@objc func moveRight(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.moveRowRight(self, row: textRow, rowStrings: rowStrings)
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
		editorDelegate?.editLink(self, result.0, text: result.1, range: result.2)
	}
	
	override func update(row: Row, indentionLevel: Int) {
		self.row = row
		self.indentionLevel = indentionLevel

		var attrs = [NSAttributedString.Key : Any]()
		if row.isComplete || row.isAncestorComplete {
			attrs[.foregroundColor] = UIColor.tertiaryLabel
			accessibilityLabel = L10n.complete
		} else {
			attrs[.foregroundColor] = UIColor.label
			accessibilityLabel = nil
		}
		
		if row.isComplete {
			attrs[.strikethroughStyle] = 1
			attrs[.strikethroughColor] = UIColor.tertiaryLabel
		} else {
			attrs[.strikethroughStyle] = 0
		}
		
		attrs[.font] = OutlineFontCache.shared.topic(level: indentionLevel)
		
		typingAttributes = attrs
		
		var linkAttrs = attrs
		linkAttrs[.underlineStyle] = 1
		linkTextAttributes = linkAttrs
		
		attributedText = row.topic
		addSearchHighlighting(isInNotes: false)
	}
	
	override func saveText() {
		guard isTextChanged, let textRow = row else { return }
		
		if isSavingTextUnnecessary {
			isSavingTextUnnecessary = false
		} else {
			editorDelegate?.textChanged(self, row: textRow, isInNotes: false, selection: selectedRange, rowStrings: rowStrings)
		}
		
		autosaveWorkItem?.cancel()
		autosaveWorkItem = nil
		isTextChanged = false
	}
	
	override func updateLinkForCurrentSelection(text: String, link: String?, range: NSRange) {
		super.updateLinkForCurrentSelection(text: text, link: link, range: range)
		textStorage.replaceFont(with: OutlineFontCache.shared.topic(level: indentionLevel))
		isTextChanged = true
		saveText()
	}
	
}

// MARK: CursorCoordinatesProvider

extension EditorTextRowTopicTextView: CursorCoordinatesProvider {

	var coordinates: CursorCoordinates? {
		if let row = row {
			return CursorCoordinates(row: row, isInNotes: false, selection: selectedRange)
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
			editorDelegate?.createRow(self, afterRow: textRow, rowStrings: rowStrings)
			return false
		default:
			return true
		}
	}
	
	func textViewDidChange(_ textView: UITextView) {
		// Break any links with a space
		let cursorLocation = selectedRange.location
		if cursorLocation > 0 {
			let range = NSRange(location: cursorLocation - 1, length: 1)
			if textView.textStorage.attributedSubstring(from: range).string == " " {
				textView.textStorage.removeAttribute(.link, range: range)
				textView.typingAttributes[.link] = nil
			}
		}
		
		isTextChanged = true

		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		if let currentHeight = textViewHeight, abs(fittingSize.height - currentHeight) > font!.capHeight / 2  {
			textViewHeight = fittingSize.height
			editorDelegate?.invalidateLayout(self)
		}
		
		editorDelegate?.makeCursorVisibleIfNecessary(self)
		
		autosaveWorkItem?.cancel()
		autosaveWorkItem = DispatchWorkItem { [weak self] in
			self?.saveText()
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: autosaveWorkItem!)
	}
	
}

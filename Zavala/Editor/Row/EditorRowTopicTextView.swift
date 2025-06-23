//
//  EditorRowTopicTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import VinOutlineKit

@MainActor
protocol EditorRowTopicTextViewDelegate: AnyObject {
	var editorRowTopicTextViewUndoManager: UndoManager? { get }
	var editorRowTopicTextViewInputAccessoryView: UIView? { get }
	func didBecomeActive(_: EditorRowTopicTextView)
	func didBecomeInactive(_: EditorRowTopicTextView)
	func resize(_: EditorRowTopicTextView)
	func scrollIfNecessary(_: EditorRowTopicTextView)
	func scrollEditorToVisible(_: EditorRowTopicTextView, rect: CGRect)
	func moveCursorUp(_: EditorRowTopicTextView, rowID: String)
	func moveCursorDown(_: EditorRowTopicTextView, rowID: String)
	func moveRowLeft(_: EditorRowTopicTextView, rowID: String)
	func textChanged(_: EditorRowTopicTextView, rowID: String, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings)
	func deleteRow(_: EditorRowTopicTextView, rowID: String, rowStrings: RowStrings)
	func createRow(_: EditorRowTopicTextView, beforeRowID: String, rowStrings: RowStrings, moveCursor: Bool)
	func createRow(_: EditorRowTopicTextView, afterRowID: String, rowStrings: RowStrings)
	func splitRow(_: EditorRowTopicTextView, rowID: String, topic: NSAttributedString, cursorPosition: Int)
	func joinRowWithPreviousSibling(_: EditorRowTopicTextView, rowID: String, attrText: NSAttributedString)
	func shouldMoveLeftOnReturn(_: EditorRowTopicTextView, rowID: String) -> Bool
	func editLink(_: EditorRowTopicTextView, _ link: String?, text: String?, range: NSRange)
	func zoomImage(_: EditorRowTopicTextView, _ image: UIImage, rect: CGRect)
}

class EditorRowTopicTextView: EditorRowTextView, EditorTextInput {
	
	override var editorUndoManager: UndoManager? {
		return editorDelegate?.editorRowTopicTextViewUndoManager
	}
	
	override var keyCommands: [UIKeyCommand]? {
		let controlP = UIKeyCommand(input: "p", modifierFlags: [.control], action: #selector(moveCursorUp(_:)))
		controlP.wantsPriorityOverSystemBehavior = true

		let controlN = UIKeyCommand(input: "n", modifierFlags: [.control], action: #selector(moveCursorDown(_:)))
		controlN.wantsPriorityOverSystemBehavior = true

		let keys = [
			controlP,
			controlN,
			UIKeyCommand(input: "\t", modifierFlags: [.alternate], action: #selector(insertTab(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.alternate], action: #selector(insertNewline(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift], action: #selector(insertRow(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift, .alternate], action: #selector(split(_:))),
		]
		
		return keys
	}
	
	weak var editorDelegate: EditorRowTopicTextViewDelegate?

	override var rowStrings: RowStrings {
		return RowStrings.topic(cleansedAttributedText)
	}
	
	var cursorIsOnTopLine: Bool {
		guard let cursorRect else { return false }
		let lineStart = closestPosition(to: CGPoint(x: 0, y: cursorRect.midY))
		return lineStart == beginningOfDocument
	}
	
	var cursorIsOnBottomLine: Bool {
		guard let cursorRect else { return false }
		let lineEnd = closestPosition(to: CGPoint(x: bounds.maxX, y: cursorRect.midY))
		return lineEnd == endOfDocument
	}
	
	var cursorIsAtBeginning: Bool {
		return position(from: beginningOfDocument, offset: cursorPosition) == beginningOfDocument
	}
	
	var cursorIsAtEnd: Bool {
		return position(from: beginningOfDocument, offset: cursorPosition) == endOfDocument
	}

	private var textStorageDelegate: EditorRowTextStorageDelegate?

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
		if result {
			editorDelegate?.didBecomeActive(self)
		}
		return result
	}
	
	override func resignFirstResponder() -> Bool {
		CursorCoordinates.updateLastKnownCoordinates()
		let result = super.resignFirstResponder()
		if result {
			editorDelegate?.didBecomeInactive(self)
		}
		return result
	}
	
    override func textWasChanged() {
        guard let rowID else { return }
        editorDelegate?.textChanged(self, rowID: rowID, isInNotes: false, selection: selectedRange, rowStrings: rowStrings)
    }

	override func resize() {
		editorDelegate?.resize(self)
	}
	
    override func scrollIfNecessary() {
        editorDelegate?.scrollIfNecessary(self)
    }
    
	override func deleteBackward() {
		guard let rowID else { return }
		
		if attributedText.length == 0 && !rowHasChildren {
			isTextChanged = false
			editorDelegate?.deleteRow(self, rowID: rowID, rowStrings: rowStrings)
			return
		}
		
		let originalTextLength = attributedText.length
		super.deleteBackward()
		
		if originalTextLength == attributedText.length && cursorIsAtBeginning {
			editorDelegate?.joinRowWithPreviousSibling(self, rowID: rowID, attrText: cleansedAttributedText)
		}
	}

	@objc func createRow(_ sender: Any) {
		guard let rowID else { return }
		editorDelegate?.createRow(self, afterRowID: rowID, rowStrings: rowStrings)
	}
	
	@objc func moveCursorUp(_ sender: Any) {
		guard let rowID else { return }
		editorDelegate?.moveCursorUp(self, rowID: rowID)
	}
	
	@objc func moveCursorDown(_ sender: Any) {
		guard let rowID else { return }
		editorDelegate?.moveCursorDown(self, rowID: rowID)
	}
	
	@objc func insertTab(_ sender: Any) {
		insertText("\t")
	}
	
	@objc func insertRow(_ sender: Any) {
		guard let rowID else { return }
		isTextChanged = false
		editorDelegate?.createRow(self, beforeRowID: rowID, rowStrings: rowStrings, moveCursor: true)
	}

	@objc func split(_ sender: Any) {
		guard let rowID else { return }
		
		isTextChanged = false

		if cursorPosition == 0 {
			editorDelegate?.createRow(self, beforeRowID: rowID, rowStrings: rowStrings, moveCursor: false)
		} else {
			editorDelegate?.splitRow(self, rowID: rowID, topic: cleansedAttributedText, cursorPosition: cursorPosition)
		}
	}
	
	@objc override func editLink(_ sender: Any?) {
		let result = findAndSelectLink()
		editorDelegate?.editLink(self, result.0, text: result.1, range: result.2)
	}
	
	func update(configuration: EditorRowContentConfiguration) {
		// Don't update the row if we are in the middle of entering multistage characters, e.g. Japanese
		guard markedTextRange == nil else { return }
		
		self.rowID = configuration.rowID
		self.rowHasChildren = configuration.rowHasChildren
		self.outlineCheckSpellingWhileTyping = configuration.outlineCheckSpellingWhileTyping
		self.outlineCorrectSpellingAutomatically = configuration.outlineCorrectSpellingAutomatically
		self.rowSearchResultCoordinates = configuration.rowSearchResultCoordinates
		
		updateTextPreferences()
		
		// We may end up here before the actual value of the text view has registered. We don't want
		// to restore the cursor location in that case because the cursor isn't actually at the beginning
		// of the line.
		var cursorRange: UITextRange? = nil
		if text != "" {
			cursorRange = selectedTextRange
		}
		
		text = ""
		
		let fontColor = if configuration.isSelected {
			UIColor.white
		} else {
			configuration.topicColor
		}
		
		baseAttributes = [NSAttributedString.Key : Any]()
		if configuration.rowIsComplete || configuration.rowIsAnyParentComplete {
			if fontColor.cgColor.alpha > 0.3 {
				baseAttributes[.foregroundColor] = fontColor.withAlphaComponent(0.3)
			} else {
				baseAttributes[.foregroundColor] = fontColor
			}
			accessibilityLabel = .completeAccessibilityLabel
		} else {
			baseAttributes[.foregroundColor] = fontColor
			accessibilityLabel = nil
		}
		
		if configuration.rowIsComplete {
			baseAttributes[.strikethroughStyle] = 1
			if fontColor.cgColor.alpha > 0.3 {
				baseAttributes[.strikethroughColor] = fontColor.withAlphaComponent(0.3)
			} else {
				baseAttributes[.strikethroughColor] = fontColor
			}
		} else {
			baseAttributes[.strikethroughStyle] = 0
		}
		
		baseAttributes[.font] = configuration.topicFont
		
		typingAttributes = baseAttributes
		
		textStorageDelegate = EditorRowTextStorageDelegate(baseAttributes: baseAttributes)
		self.textStorage.delegate = textStorageDelegate

		var linkAttrs = baseAttributes
		linkAttrs[.underlineStyle] = 1
		linkTextAttributes = linkAttrs
		
		if let topic = configuration.rowTopic {
            attributedText = topic
        }
        
		addSearchHighlighting(isInNotes: false)
		
		if let cursorRange {
			selectedTextRange = cursorRange
		}
    }
	
	override func scrollEditorToVisible(rect: CGRect) {
		editorDelegate?.scrollEditorToVisible(self, rect: rect)
	}
	
}

// MARK: CursorCoordinatesProvider

extension EditorRowTopicTextView: CursorCoordinatesProvider {

	var coordinates: CursorCoordinates? {
		if let rowID {
			return CursorCoordinates(rowID: rowID, isInNotes: false, selection: selectedRange)
		}
		return nil
	}

}

// MARK: UITextViewDelegate

extension EditorRowTopicTextView: UITextViewDelegate {
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		processTextEditingBegin()
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
        processTextEditingEnding()
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		guard let rowID else { return true }
		
		switch text {
		case "\n":
			if cursorIsAtBeginning {
				if editorDelegate?.shouldMoveLeftOnReturn(self, rowID: rowID) ?? false {
					editorDelegate?.moveRowLeft(self, rowID: rowID)
				} else {
					isTextChanged = false
					editorDelegate?.createRow(self, beforeRowID: rowID, rowStrings: rowStrings, moveCursor: false)
				}
			} else if cursorIsAtEnd {
				isTextChanged = false
				editorDelegate?.createRow(self, afterRowID: rowID, rowStrings: rowStrings)
			} else {
				isTextChanged = false
				editorDelegate?.splitRow(self, rowID: rowID, topic: cleansedAttributedText, cursorPosition: cursorPosition)
			}
			return false
		default:
			return true
		}
	}
	
    func textViewDidChange(_ textView: UITextView) {
        processTextChanges()
    }
    
	func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
		if case .textAttachment(let attachment) = textItem.content,
		   let firstRect = firstRect(for: textItem.range),
		   let image = attachment.image {
			
			return UIAction { [weak self] action in
				guard let self else { return }
				let convertedRect = convert(firstRect, to: nil)
				self.editorDelegate?.zoomImage(self, image, rect: convertedRect)
			}
							
		}
							
		return defaultAction
	}
	
	func textViewDidChangeSelection(_ textView: UITextView) {
		handleDidChangeSelection()
	}

}

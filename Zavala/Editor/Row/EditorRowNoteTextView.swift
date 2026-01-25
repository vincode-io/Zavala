//
//  EditorRowNoteTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/13/20.
//

import UIKit
import VinOutlineKit
import SwiftUI

@MainActor
protocol EditorRowNoteTextViewDelegate: AnyObject {
	var editorRowNoteTextViewUndoManager: UndoManager? { get }
	var editorRowNoteTextViewInputAccessoryView: UIView? { get }
	func resize(_ : EditorRowNoteTextView)
	func scrollIfNecessary(_ : EditorRowNoteTextView)
	func scrollEditorToVisible(_ : EditorRowNoteTextView, rect: CGRect)
	func didBecomeActive(_ : EditorRowNoteTextView)
	func didBecomeInactive(_ : EditorRowNoteTextView)
	func textChanged(_ : EditorRowNoteTextView, rowID: String, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings)
	func deleteRowNote(_ : EditorRowNoteTextView, rowID: String)
	func moveCursorTo(_ : EditorRowNoteTextView, rowID: String)
	func moveCursorDown(_ : EditorRowNoteTextView, rowID: String)
	func editLink(_: EditorRowNoteTextView, _ link: String?, text: String?, range: NSRange)
	func zoomImage(_: EditorRowNoteTextView, _ image: UIImage, rect: CGRect)
}

class EditorRowNoteTextView: EditorRowTextView {
	
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
		return keys
	}
	
	weak var editorDelegate: EditorRowNoteTextViewDelegate?

	override var coordinates: CursorCoordinates? {
		if let rowID {
			return CursorCoordinates(rowID: rowID, isInNotes: true, selection: selectedRange)
		}
		return nil
	}

	override var rowStrings: RowStrings {
		return RowStrings.note(cleansedAttributedText)
	}

	private var textStorageDelegate: EditorRowTextStorageDelegate?
	
	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		
		self.delegate = self

		self.textColor = .secondaryLabel
		self.linkTextAttributes = [.foregroundColor: UIColor.secondaryLabel, .underlineStyle: 1]
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@discardableResult
	override func becomeFirstResponder() -> Bool {
		inputAccessoryView = editorDelegate?.editorRowNoteTextViewInputAccessoryView
		let result = super.becomeFirstResponder()
		if result {
			editorDelegate?.didBecomeActive(self)
		}
		return result
	}
	
	override func resignFirstResponder() -> Bool {
		let result = super.resignFirstResponder()
		if result {
			editorDelegate?.didBecomeInactive(self)
		}
		return result
	}
	
    override func textWasChanged() {
        guard let rowID else { return }
        editorDelegate?.textChanged(self, rowID: rowID, isInNotes: true, selection: selectedRange, rowStrings: rowStrings)
    }
    
	override func resize() {
		editorDelegate?.resize(self)
	}
    
    override func scrollIfNecessary() {
        editorDelegate?.scrollIfNecessary(self)
    }
    
	override func deleteBackward() {
		guard let rowID else { return }
		if attributedText.length == 0 {
			isTextChanged = false
			editorDelegate?.deleteRowNote(self, rowID: rowID)
		} else {
			super.deleteBackward()
		}
	}

	@objc func moveCursorToText(_ sender: Any) {
		guard let rowID else { return }
		editorDelegate?.moveCursorTo(self, rowID: rowID)
	}
	
	@objc func moveCursorDown(_ sender: Any) {
		guard let rowID else { return }
		editorDelegate?.moveCursorDown(self, rowID: rowID)
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
			UIColor.white.withAlphaComponent(0.66)
		} else {
			configuration.noteColor
		}
		
		baseAttributes = [NSAttributedString.Key : Any]()
		baseAttributes[.font] = configuration.noteFont
		baseAttributes[.foregroundColor] = fontColor

		typingAttributes = baseAttributes
		
		textStorageDelegate = EditorRowTextStorageDelegate(baseAttributes: baseAttributes)
		self.textStorage.delegate = textStorageDelegate
		
		var linkAttrs = baseAttributes
		linkAttrs[.underlineStyle] = 1
		linkTextAttributes = linkAttrs
		
		if let note = configuration.rowNote {
            attributedText = note
        }
        
		addSearchHighlighting(isInNotes: true)
		
		if let cursorRange {
			selectedTextRange = cursorRange
		}
    }

	override func scrollEditorToVisible(rect: CGRect) {
		editorDelegate?.scrollEditorToVisible(self, rect: rect)
	}

}

// MARK: UITextViewDelegate

extension EditorRowNoteTextView: UITextViewDelegate {
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		processTextEditingBegin()
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
        processTextEditingEnding()
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

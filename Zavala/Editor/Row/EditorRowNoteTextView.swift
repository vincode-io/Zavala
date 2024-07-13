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
	func didBecomeActive(_ : EditorRowNoteTextView, row: Row)
	func textChanged(_ : EditorRowNoteTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings)
	func deleteRowNote(_ : EditorRowNoteTextView, row: Row, rowStrings: RowStrings)
	func moveCursorTo(_ : EditorRowNoteTextView, row: Row)
	func moveCursorDown(_ : EditorRowNoteTextView, row: Row)
	func editLink(_: EditorRowNoteTextView, _ link: String?, text: String?, range: NSRange)
	func zoomImage(_: EditorRowNoteTextView, _ image: UIImage, rect: CGRect)
}

class EditorRowNoteTextView: EditorRowTextView, EditorTextInput {
	
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
	
	weak var editorDelegate: EditorRowNoteTextViewDelegate?
	
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
			didBecomeActive()
		}
		return result
	}
	
	func didBecomeActive() {
		if let row {
			editorDelegate?.didBecomeActive(self, row: row)
		}
	}
	
    override func textWasChanged() {
        guard let row else { return }
        editorDelegate?.textChanged(self, row: row, isInNotes: true, selection: selectedRange, rowStrings: rowStrings)
    }
    
	override func resize() {
		editorDelegate?.resize(self)
	}
    
    override func scrollIfNecessary() {
        editorDelegate?.scrollIfNecessary(self)
    }
    
	override func deleteBackward() {
		guard let row else { return }
		if attributedText.length == 0 {
			isSavingTextUnnecessary = true
			editorDelegate?.deleteRowNote(self, row: row, rowStrings: rowStrings)
		} else {
			super.deleteBackward()
		}
	}

	@objc func moveCursorToText(_ sender: Any) {
		guard let row else { return }
		editorDelegate?.moveCursorTo(self, row: row)
	}
	
	@objc func moveCursorDown(_ sender: Any) {
		guard let row else { return }
		editorDelegate?.moveCursorDown(self, row: row)
	}

	@objc override func editLink(_ sender: Any?) {
		let result = findAndSelectLink()
		editorDelegate?.editLink(self, result.0, text: result.1, range: result.2)
	}
	
	override func update(row: Row) {
		// Don't update the row if we are in the middle of entering multistage characters, e.g. Japanese
		guard markedTextRange == nil else { return }
		
		self.row = row
		
		updateTextPreferences()
		
		let cursorRange = selectedTextRange
		
		text = ""
		
		baseAttributes = [NSAttributedString.Key : Any]()
		baseAttributes[.font] = OutlineFontCache.shared.noteFont(level: row.trueLevel)
		baseAttributes[.foregroundColor] = OutlineFontCache.shared.noteColor(level: row.trueLevel)

		typingAttributes = baseAttributes
		
		textStorageDelegate = EditorRowTextStorageDelegate(baseAttributes: baseAttributes)
		self.textStorage.delegate = textStorageDelegate
		
        if let note = row.note {
            attributedText = note
        }
        
		addSearchHighlighting(isInNotes: true)
		
		selectedTextRange = cursorRange
    }

	override func scrollEditorToVisible(rect: CGRect) {
		editorDelegate?.scrollEditorToVisible(self, rect: rect)
	}

}

// MARK: CursorCoordinatesProvider

extension EditorRowNoteTextView: CursorCoordinatesProvider {

	var coordinates: CursorCoordinates? {
		if let row {
			return CursorCoordinates(row: row, isInNotes: true, selection: selectedRange)
		}
		return nil
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

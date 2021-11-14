//
//  EditorRowNoteTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/13/20.
//

import UIKit
import Templeton
import SwiftUI

protocol EditorRowNoteTextViewDelegate: AnyObject {
	var editorRowNoteTextViewUndoManager: UndoManager? { get }
	var editorRowNoteTextViewInputAccessoryView: UIView? { get }
	func layoutEditor(_ : EditorRowNoteTextView)
	func makeCursorVisibleIfNecessary(_ : EditorRowNoteTextView)
	func didBecomeActive(_ : EditorRowNoteTextView, row: Row)
	func textChanged(_ : EditorRowNoteTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings)
	func deleteRowNote(_ : EditorRowNoteTextView, row: Row, rowStrings: RowStrings)
	func moveCursorTo(_ : EditorRowNoteTextView, row: Row)
	func moveCursorDown(_ : EditorRowNoteTextView, row: Row)
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
		keys.append(toggleBoldCommand)
		keys.append(toggleItalicsCommand)
		keys.append(editLinkCommand)
		return keys
	}
	
	weak var editorDelegate: EditorRowNoteTextViewDelegate?
	
	override var rowStrings: RowStrings {
		return RowStrings.note(cleansedAttributedText)
	}

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
		didBecomeActive()
		return result
	}
	
	func didBecomeActive() {
		if let row = row {
			editorDelegate?.didBecomeActive(self, row: row)
		}
	}
	
    override func textWasChanged() {
        guard let row = row else { return }
        editorDelegate?.textChanged(self, row: row, isInNotes: true, selection: selectedRange, rowStrings: rowStrings)
    }
    
	override func layoutEditor() {
        editorDelegate?.layoutEditor(self)
	}
    
    override func makeCursorVisibleIfNecessary() {
        editorDelegate?.makeCursorVisibleIfNecessary(self)
    }
    
	override func deleteBackward() {
		guard let row = row else { return }
		if attributedText.length == 0 {
			isSavingTextUnnecessary = true
			editorDelegate?.deleteRowNote(self, row: row, rowStrings: rowStrings)
		} else {
			super.deleteBackward()
		}
	}

	@objc func moveCursorToText(_ sender: Any) {
		guard let row = row else { return }
		editorDelegate?.moveCursorTo(self, row: row)
	}
	
	@objc func moveCursorDown(_ sender: Any) {
		guard let row = row else { return }
		editorDelegate?.moveCursorDown(self, row: row)
	}

	@objc override func editLink(_ sender: Any?) {
		let result = findAndSelectLink()
		editorDelegate?.editLink(self, result.0, text: result.1, range: result.2)
	}
	
	override func update(row: Row) {
		self.row = row
		
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.foregroundColor] = UIColor.secondaryLabel
		attrs[.font] = OutlineFontCache.shared.note(level: row.level)
		
		typingAttributes = attrs
        
        if let note = row.note {
            attributedText = note
        } else {
            text = ""
        }
        
		addSearchHighlighting(isInNotes: true)
    }
	
}

// MARK: CursorCoordinatesProvider

extension EditorRowNoteTextView: CursorCoordinatesProvider {

	var coordinates: CursorCoordinates? {
		if let row = row {
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
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		switch text {
		case " ":
			typingAttributes[.link] = nil
			return true
		default:
			return true
		}
	}
	
    func textViewDidChange(_ textView: UITextView) {
        processTextChanges()
    }
    
	func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
		guard interaction == .invokeDefaultAction,
			  let firstRect = firstRect(for: characterRange),
			  let image = textAttachment.image	else { return true }
		
		let convertedRect = convert(firstRect, to: nil)
		editorDelegate?.zoomImage(self, image, rect: convertedRect)
		return false
	}
}

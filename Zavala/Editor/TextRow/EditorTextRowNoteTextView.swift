//
//  EditorTextRowNoteTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/13/20.
//

import UIKit
import Templeton
import SwiftUI

protocol EditorTextRowNoteTextViewDelegate: AnyObject {
	var editorRowNoteTextViewUndoManager: UndoManager? { get }
	var editorRowNoteTextViewInputAccessoryView: UIView? { get }
	func reload(_ : EditorTextRowNoteTextView, row: Row)
	func makeCursorVisibleIfNecessary(_ : EditorTextRowNoteTextView)
	func didBecomeActive(_ : EditorTextRowNoteTextView, row: Row)
	func textChanged(_ : EditorTextRowNoteTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings)
	func deleteRowNote(_ : EditorTextRowNoteTextView, row: Row, rowStrings: RowStrings)
	func moveCursorTo(_ : EditorTextRowNoteTextView, row: Row)
	func moveCursorDown(_ : EditorTextRowNoteTextView, row: Row)
	func editLink(_: EditorTextRowNoteTextView, _ link: String?, text: String?, range: NSRange)
}

class EditorTextRowNoteTextView: EditorTextRowTextView {
	
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
	
	weak var editorDelegate: EditorTextRowNoteTextViewDelegate?
	
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
        guard let textRow = row else { return }
        editorDelegate?.textChanged(self, row: textRow, isInNotes: true, selection: selectedRange, rowStrings: rowStrings)
    }
    
	override func reloadRow() {
        guard let textRow = row else { return }
        editorDelegate?.reload(self, row: textRow)
	}
    
    override func makeCursorVisibleIfNecessary() {
        editorDelegate?.makeCursorVisibleIfNecessary(self)
    }
    
	override func deleteBackward() {
		guard let textRow = row else { return }
		if attributedText.length == 0 {
			isSavingTextUnnecessary = true
			editorDelegate?.deleteRowNote(self, row: textRow, rowStrings: rowStrings)
		} else {
			super.deleteBackward()
		}
	}

	@objc func moveCursorToText(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.moveCursorTo(self, row: textRow)
	}
	
	@objc func moveCursorDown(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.moveCursorDown(self, row: textRow)
	}

	@objc override func editLink(_ sender: Any?) {
		let result = findAndSelectLink()
		editorDelegate?.editLink(self, result.0, text: result.1, range: result.2)
	}
	
	override func update(row: Row, indentionLevel: Int) {
		self.row = row
		self.indentionLevel = indentionLevel
		
		var attrs = [NSAttributedString.Key : Any]()
		attrs[.foregroundColor] = UIColor.secondaryLabel
		attrs[.font] = OutlineFontCache.shared.note(level: indentionLevel)
		
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

extension EditorTextRowNoteTextView: CursorCoordinatesProvider {

	var coordinates: CursorCoordinates? {
		if let row = row {
			return CursorCoordinates(row: row, isInNotes: true, selection: selectedRange)
		}
		return nil
	}

}

// MARK: UITextViewDelegate

extension EditorTextRowNoteTextView: UITextViewDelegate {
	
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
    
}

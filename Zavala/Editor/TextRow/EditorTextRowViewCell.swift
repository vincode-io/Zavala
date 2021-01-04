//
//  EditorTextRowViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit
import Templeton

protocol EditorTextRowViewCellDelegate: class {
	var editorTextRowUndoManager: UndoManager? { get }
	func editorTextRowLayoutEditor()
	func editorTextRowTextFieldDidBecomeActive()
	func editorTextRowToggleDisclosure(row: Row)
	func editorTextRowMoveCursorTo(row: Row)
	func editorTextRowMoveCursorDown(row: Row)
	func editorTextRowTextChanged(row: Row, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int)
	func editorTextRowDeleteRow(_ row: Row, textRowStrings: TextRowStrings)
	func editorTextRowCreateRow(beforeRow: Row)
	func editorTextRowCreateRow(afterRow: Row?, textRowStrings: TextRowStrings?)
	func editorTextRowIndentRow(_ row: Row, textRowStrings: TextRowStrings)
	func editorTextRowOutdentRow(_ row: Row, textRowStrings: TextRowStrings)
	func editorTextRowSplitRow(_: Row, topic: NSAttributedString, cursorPosition: Int)
	func editorTextRowCreateRowNote(_ row: Row, textRowStrings: TextRowStrings)
	func editorTextRowDeleteRowNote(_ row: Row, textRowStrings: TextRowStrings)
	func editorTextRowEditLink(_ link: String?, range: NSRange)
}

class EditorTextRowViewCell: UICollectionViewListCell {

	var row: Row? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	var isNotesHidden: Bool? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	weak var delegate: EditorTextRowViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	var textRowStrings: TextRowStrings? {
		return (contentView as? EditorTextRowContentView)?.textRowStrings
	}
	
	var topicTextView: EditorTextRowTopicTextView? {
		return (contentView as? EditorTextRowContentView)?.topicTextView
	}
	
	var noteTextView: EditorTextRowNoteTextView? {
		return (contentView as? EditorTextRowContentView)?.noteTextView
	}
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		
		layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

		guard let row = row else { return }

		indentationLevel = row.indentLevel

		// We make the indentation width the same regardless of device if not compact
		if traitCollection.horizontalSizeClass != .compact {
			indentationWidth = 13
		} else {
			indentationWidth = 10
		}
		
		var content = EditorTextRowContentConfiguration(row: row, indentionLevel: indentationLevel, indentationWidth: indentationWidth, isNotesHidden: isNotesHidden ?? false)
		content = content.updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}

	func restoreSelection(_ textRange: UITextRange) {
		guard let textView = (contentView as? EditorTextRowContentView)?.topicTextView else { return }
		textView.becomeFirstResponder()
		textView.selectedTextRange = textRange
	}
	
	func restoreCursor(_ cursorCoordinates: CursorCoordinates) {
		let textView: OutlineTextView?
		if cursorCoordinates.isInNotes {
			textView = (contentView as? EditorTextRowContentView)?.noteTextView
		} else {
			textView = (contentView as? EditorTextRowContentView)?.topicTextView
		}
		
		if let textView = textView, let textPosition = textView.position(from: textView.beginningOfDocument, offset: cursorCoordinates.cursorPosition) {
			textView.becomeFirstResponder()
			textView.selectedTextRange = textView.textRange(from: textPosition, to: textPosition)
		} else if let textView = textView {
			textView.becomeFirstResponder()
			let endPosition = textView.endOfDocument
			textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
		}
	}
	
	func moveToStart() {
		guard let textView = (contentView as? EditorTextRowContentView)?.topicTextView else { return }
		textView.becomeFirstResponder()
		let startPosition = textView.beginningOfDocument
		textView.selectedTextRange = textView.textRange(from: startPosition, to: startPosition)
	}
	
	func moveToEnd() {
		guard let textView = (contentView as? EditorTextRowContentView)?.topicTextView else { return }
		textView.becomeFirstResponder()
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
	}
	
	func moveToNote() {
		guard let textView = (contentView as? EditorTextRowContentView)?.noteTextView else { return }
		textView.becomeFirstResponder()
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
	}
	
}

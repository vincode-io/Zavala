//
//  EditorTextRowViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit
import Templeton

protocol EditorTextRowViewCellDelegate: AnyObject {
	var editorTextRowUndoManager: UndoManager? { get }
	var editorTextRowInputAccessoryView: UIView? { get }
	func editorTextRowReloadCurrentCell()
	func editorTextRowMakeCursorVisibleIfNecessary()
	func editorTextRowTextFieldDidBecomeActive(row: Row)
	func editorTextRowToggleDisclosure(row: Row)
	func editorTextRowMoveCursorTo(row: Row)
	func editorTextRowMoveCursorDown(row: Row)
	func editorTextRowTextChanged(row: Row, rowStrings: RowStrings, isInNotes: Bool, selection: NSRange)
	func editorTextRowDeleteRow(_ row: Row, rowStrings: RowStrings)
	func editorTextRowCreateRow(beforeRow: Row)
	func editorTextRowCreateRow(afterRow: Row?, rowStrings: RowStrings?)
	func editorTextRowMoveRowLeft(_ row: Row, rowStrings: RowStrings)
	func editorTextRowMoveRowRight(_ row: Row, rowStrings: RowStrings)
	func editorTextRowSplitRow(_: Row, topic: NSAttributedString, cursorPosition: Int)
	func editorTextRowDeleteRowNote(_ row: Row, rowStrings: RowStrings)
	func editorTextRowEditLink(_ link: String?, text: String?, range: NSRange)
}

class EditorTextRowViewCell: UICollectionViewListCell {

	var row: Row? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	var isNotesHidden: Bool = false {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	var isSearching: Bool = false {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	weak var delegate: EditorTextRowViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
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

		indentationLevel = row.level

		// We make the indentation width the same regardless of device if not compact
		if traitCollection.horizontalSizeClass != .compact {
			indentationWidth = 16
		} else {
			indentationWidth = 13
		}
		
		var content = EditorTextRowContentConfiguration(row: row, indentionLevel: indentationLevel, indentationWidth: indentationWidth, isNotesHidden: isNotesHidden, isSearching: isSearching)
		content = content.updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}

	func restoreCursor(_ cursorCoordinates: CursorCoordinates) {
		let textView: EditorTextRowTextView?
		if cursorCoordinates.isInNotes {
			textView = (contentView as? EditorTextRowContentView)?.noteTextView
		} else {
			textView = (contentView as? EditorTextRowContentView)?.topicTextView
		}
		
		if let textView = textView,
		   let startPosition = textView.position(from: textView.beginningOfDocument, offset: cursorCoordinates.selection.location),
		   let endPosition = textView.position(from: startPosition, offset: cursorCoordinates.selection.length) {
			textView.becomeFirstResponder()
			textView.selectedTextRange = textView.textRange(from: startPosition, to: endPosition)
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
		// If you don't set the cursor location this way, sometimes if just doesn't appear.  Weird, I know.
		textView.selectedTextRange = textView.textRange(from: startPosition, to: textView.endOfDocument)
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

//
//  EditorRowViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit
import Templeton

protocol EditorRowViewCellDelegate: AnyObject {
	var editorRowUndoManager: UndoManager? { get }
	var editorRowInputAccessoryView: UIView? { get }
    func editorRowLayoutEditor()
	func editorRowMakeCursorVisibleIfNecessary()
	func editorRowTextFieldDidBecomeActive(row: Row)
	func editorRowToggleDisclosure(row: Row, applyToAll: Bool)
	func editorRowMoveCursorTo(row: Row)
	func editorRowMoveCursorUp(row: Row)
	func editorRowMoveCursorDown(row: Row)
	func editorRowTextChanged(row: Row, rowStrings: RowStrings, isInNotes: Bool, selection: NSRange)
	func editorRowDeleteRow(_ row: Row, rowStrings: RowStrings)
	func editorRowCreateRow(beforeRow: Row)
	func editorRowCreateRow(afterRow: Row?, rowStrings: RowStrings?)
	func editorRowMoveRowLeft(_ row: Row, rowStrings: RowStrings)
	func editorRowMoveRowRight(_ row: Row, rowStrings: RowStrings)
	func editorRowSplitRow(_: Row, topic: NSAttributedString, cursorPosition: Int)
	func editorRowDeleteRowNote(_ row: Row, rowStrings: RowStrings)
	func editorRowEditLink(_ link: String?, text: String?, range: NSRange)
	func editorRowZoomImage(_ image: UIImage, rect: CGRect)
}

class EditorRowViewCell: UICollectionViewListCell {

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
	
	weak var delegate: EditorRowViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	var topicTextView: EditorRowTopicTextView? {
		return (contentView as? EditorRowContentView)?.topicTextView
	}
	
	var noteTextView: EditorRowNoteTextView? {
		return (contentView as? EditorRowContentView)?.noteTextView
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
		
		let isDisclosureVisible = row.rowCount != 0
		let isNotesVisible = !isNotesHidden && !row.isNoteEmpty
		
		var content = EditorRowContentConfiguration(row: row,
													isSearching: isSearching,
													isDisclosureVisible: isDisclosureVisible,
													isNotesVisible: isNotesVisible,
													horizontalSizeClass: traitCollection.horizontalSizeClass)
		
		content = content.updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}

	func restoreCursor(_ cursorCoordinates: CursorCoordinates) {
		let textView: EditorRowTextView?
		if cursorCoordinates.isInNotes {
			textView = (contentView as? EditorRowContentView)?.noteTextView
		} else {
			textView = (contentView as? EditorRowContentView)?.topicTextView
		}
		
		if let textView = textView,
		   let startPosition = textView.position(from: textView.beginningOfDocument, offset: cursorCoordinates.selection.location),
		   let endPosition = textView.position(from: startPosition, offset: cursorCoordinates.selection.length) {
			textView.selectedTextRange = textView.textRange(from: startPosition, to: endPosition)
			textView.becomeFirstResponder()
		} else if let textView = textView {
			let endPosition = textView.endOfDocument
			textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
			textView.becomeFirstResponder()
		}
	}
	
	func moveToStart() {
		guard let textView = (contentView as? EditorRowContentView)?.topicTextView else { return }
		let startPosition = textView.beginningOfDocument
		// If you don't set the cursor location this way, sometimes if just doesn't appear.  Weird, I know.
		textView.selectedTextRange = textView.textRange(from: startPosition, to: textView.endOfDocument)
		textView.selectedTextRange = textView.textRange(from: startPosition, to: startPosition)
		textView.becomeFirstResponder()
	}
	
	func moveToEnd() {
		guard let textView = (contentView as? EditorRowContentView)?.topicTextView else { return }
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
		textView.becomeFirstResponder()
	}
	
	func moveToNote() {
		guard let textView = (contentView as? EditorRowContentView)?.noteTextView else { return }
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
		textView.becomeFirstResponder()
	}
	
}

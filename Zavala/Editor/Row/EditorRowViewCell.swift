//
//  EditorRowViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit
import VinOutlineKit

@MainActor
protocol EditorRowViewCellDelegate: AnyObject {
	var editorRowUndoManager: UndoManager? { get }
	var editorRowInputAccessoryView: UIView? { get }
	func editorRowScrollIfNecessary()
	func editorRowScrollEditorToVisible(textView: UITextView, rect: CGRect)
	func editorRowTextFieldDidBecomeActive()
	func editorRowTextFieldDidBecomeInactive()
	func editorRowToggleDisclosure(row: Row, applyToAll: Bool)
	func editorRowMoveCursorTo(row: Row)
	func editorRowMoveCursorUp(row: Row)
	func editorRowMoveCursorDown(row: Row)
	func editorRowMoveRowLeft(row: Row)
	func editorRowTextChanged(row: Row, rowStrings: RowStrings, isInNotes: Bool, selection: NSRange)
	func editorRowDeleteRow(_ row: Row, rowStrings: RowStrings)
	func editorRowCreateRow(beforeRow: Row, rowStrings: RowStrings?, moveCursor: Bool)
	func editorRowCreateRow(afterRow: Row?, rowStrings: RowStrings?)
	func editorRowSplitRow(_: Row, topic: NSAttributedString, cursorPosition: Int)
	func editorRowJoinRow(_: Row, topic: NSAttributedString)
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
	
	var rowIndentSize: DefaultsSize? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	var rowSpacingSize: DefaultsSize? {
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
	
	var numberingStyle: Outline.NumberingStyle? {
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

		guard let row else { return }

		indentationLevel = row.currentLevel

		switch rowIndentSize {
		case .small:
			indentationWidth = 10
		case .medium:
			indentationWidth = 13
		default:
			indentationWidth = 16
		}

		
		let isDisclosureVisible = row.rowCount != 0
		let isNotesVisible = !isNotesHidden && !row.isNoteEmpty
		
		var content = EditorRowContentConfiguration(row: row,
													isSearching: isSearching,
													numberingStyle: numberingStyle,
													indentationWidth: indentationWidth,
													isDisclosureVisible: isDisclosureVisible,
													isNotesVisible: isNotesVisible,
													rowIndentSize: rowIndentSize,
													rowSpacingSize: rowSpacingSize)
		
		content = content.updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}
	
	func isDroppable(session: UIDropSession) -> Bool {
		let cursorLocation = session.location(in: self)
		return (bounds.minY < cursorLocation.y && bounds.maxY - 1 > cursorLocation.y)
	}

	func restoreCursor(_ cursorCoordinates: CursorCoordinates) {
		let textView: EditorRowTextView?
		if cursorCoordinates.isInNotes {
			textView = (contentView as? EditorRowContentView)?.noteTextView
		} else {
			textView = (contentView as? EditorRowContentView)?.topicTextView
		}
		
		if let textView,
		   let startPosition = textView.position(from: textView.beginningOfDocument, offset: cursorCoordinates.selection.location),
		   let endPosition = textView.position(from: startPosition, offset: cursorCoordinates.selection.length) {
			textView.selectedTextRange = textView.textRange(from: startPosition, to: endPosition)
			textView.becomeFirstResponder()
		} else if let textView {
			let endPosition = textView.endOfDocument
			textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
			textView.becomeFirstResponder()
		}
	}
	
	func moveToTopicStart() {
		guard let textView = (contentView as? EditorRowContentView)?.topicTextView else { return }
		let startPosition = textView.beginningOfDocument
		// If you don't set the cursor location this way, sometimes if just doesn't appear.  Weird, I know.
		textView.selectedTextRange = textView.textRange(from: startPosition, to: textView.endOfDocument)
		textView.selectedTextRange = textView.textRange(from: startPosition, to: startPosition)
		textView.becomeFirstResponder()
	}
	
	func moveToTopicEnd() {
		guard let textView = (contentView as? EditorRowContentView)?.topicTextView else { return }
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
		textView.becomeFirstResponder()
	}
	
	func moveToNoteEnd() {
		guard let textView = (contentView as? EditorRowContentView)?.noteTextView else { return }
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
		textView.becomeFirstResponder()
	}
	
}

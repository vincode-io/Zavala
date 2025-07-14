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
	func editorRowToggleDisclosure(rowID: String, applyToAll: Bool)
	func editorRowMoveCursorTo(rowID: String)
	func editorRowMoveCursorUp(rowID: String)
	func editorRowMoveCursorDown(rowID: String)
	func editorRowMoveRowLeft(rowID: String)
	func editorRowMoveRowRight(rowID: String)
	func editorRowTextChanged(rowID: String, rowStrings: RowStrings, isInNotes: Bool, selection: NSRange)
	func editorRowDeleteRow(rowID: String, rowStrings: RowStrings)
	func editorRowCreateRow(beforeRowID: String, rowStrings: RowStrings?, moveCursor: Bool)
	func editorRowCreateRow(afterRowID: String, rowStrings: RowStrings?)
	func editorRowSplitRow(rowID: String, topic: NSAttributedString, cursorPosition: Int)
	func editorRowJoinRowWithPreviousSibling(rowID: String, attrText: NSAttributedString)
	func editorRowShouldMoveLeftOnReturn(rowID: String) -> Bool
	func editorRowDeleteRowNote(rowID: String)
	func editorRowEditLink(_ link: String?, text: String?, range: NSRange)
	func editorRowZoomImage(_ image: UIImage, rect: CGRect)
}

class EditorRowViewCell: UICollectionViewListCell {

	var row: Row?
	var rowIndentSize: DefaultsSize?
	var rowSpacingSize: DefaultsSize?
	var isSearching: Bool = false
	weak var delegate: EditorRowViewCellDelegate?
	
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
		let isNotesVisible = !(row.outline?.isNotesFilterOn ?? false) && !row.isNoteEmpty
		let isSelected = state.isSelected
		let hasChildren = row.rowCount > 0
		
		var searchResultCoordinates = [SearchResultCoordinates]()
		for src in row.searchResultCoordinates.allObjects {
			searchResultCoordinates.append(SearchResultCoordinates(isCurrentResult: src.isCurrentResult, row: src.row, isInNotes: src.isInNotes, range: src.range))
		}
		
		let numberingFont = OutlineFontCache.shared.numberingFont(level: row.trueLevel)
		let numberingColor = OutlineFontCache.shared.numberingColor(level: row.trueLevel)
		let topicFont = OutlineFontCache.shared.topicFont(level: row.trueLevel)
		let topicColor = OutlineFontCache.shared.topicColor(level: row.trueLevel)
		let noteFont = OutlineFontCache.shared.noteFont(level: row.trueLevel)
		let noteColor = OutlineFontCache.shared.noteColor(level: row.trueLevel)

		var content = EditorRowContentConfiguration(rowID: row.id,
													rowTopic: row.topic,
													rowNote: row.note,
													rowHasChildren: hasChildren,
													rowIsExpanded: row.isExpanded,
													rowOutlineNumbering: row.outlineNumbering,
													rowCurrentLevel: row.currentLevel,
													rowIsComplete: row.isComplete ?? false,
													rowIsAnyParentComplete: row.isAnyParentComplete,
													rowSearchResultCoordinates: searchResultCoordinates,
													isSearching: isSearching,
													outlineNumberingStyle: row.outline?.numberingStyle,
													outlineCheckSpellingWhileTyping: row.outline?.checkSpellingWhileTyping ?? true,
													outlineCorrectSpellingAutomatically: row.outline?.correctSpellingAutomatically ?? true,
													indentationWidth: indentationWidth,
													isDisclosureVisible: isDisclosureVisible,
													isNotesVisible: isNotesVisible,
													isSelected: isSelected,
													rowIndentSize: rowIndentSize,
													rowSpacingSize: rowSpacingSize,
													numberingFont: numberingFont,
													numberingColor: numberingColor,
													topicFont: topicFont,
													topicColor: topicColor,
													noteFont: noteFont,
													noteColor: noteColor)

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

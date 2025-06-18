//
//  EditorRowContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import VinOutlineKit

struct EditorRowContentConfiguration: UIContentConfiguration, Equatable {

	weak var delegate: EditorRowViewCellDelegate? = nil

	let rowID: String
	let rowTopic: NSAttributedString?
	let rowNote: NSAttributedString?
	let rowHasChildren: Bool
	let rowIsExpanded: Bool
	let rowOutlineNumbering: String?
	let rowCurrentLevel: Int
	let rowTrueLevel: Int
	let rowIsComplete: Bool
	let rowIsAnyParentComplete: Bool
	let rowSearchResultCoordinates: [SearchResultCoordinates]
	
	let isSearching: Bool
	
	let outlineNumberingStyle: Outline.NumberingStyle?
	let outlineCheckSpellingWhileTyping: Bool
	let outlineCorrectSpellingAutomatically: Bool
	
	let indentationWidth: CGFloat
	let isDisclosureVisible: Bool
	let isNotesVisible: Bool
	let isSelected: Bool
	let rowIndentSize: DefaultsSize?
	let rowSpacingSize: DefaultsSize?
	
	init(rowID: String,
		 rowTopic: NSAttributedString?,
		 rowNote: NSAttributedString?,
		 rowHasChildren: Bool,
		 rowIsExpanded: Bool,
		 rowOutlineNumbering: String?,
		 rowCurrentLevel: Int,
		 rowTrueLevel: Int,
		 rowIsComplete: Bool,
		 rowIsAnyParentComplete: Bool,
		 rowSearchResultCoordinates: [SearchResultCoordinates],
		 isSearching: Bool,
		 outlineNumberingStyle: Outline.NumberingStyle?,
		 outlineCheckSpellingWhileTyping: Bool,
		 outlineCorrectSpellingAutomatically: Bool,
		 indentationWidth: CGFloat,
		 isDisclosureVisible: Bool,
		 isNotesVisible: Bool,
		 isSelected: Bool,
		 rowIndentSize: DefaultsSize?,
		 rowSpacingSize: DefaultsSize?) {
		self.rowID = rowID
		self.rowTopic = rowTopic
		self.rowNote = rowNote
		self.rowHasChildren = rowHasChildren
		self.rowIsExpanded = rowIsExpanded
		self.rowOutlineNumbering = rowOutlineNumbering
		self.rowCurrentLevel = rowCurrentLevel
		self.rowTrueLevel = rowTrueLevel
		self.rowIsComplete = rowIsComplete
		self.rowIsAnyParentComplete = rowIsAnyParentComplete
		self.rowSearchResultCoordinates = rowSearchResultCoordinates
		self.isSearching = isSearching
		self.outlineNumberingStyle = outlineNumberingStyle
		self.outlineCheckSpellingWhileTyping = outlineCheckSpellingWhileTyping
		self.outlineCorrectSpellingAutomatically = outlineCorrectSpellingAutomatically
		self.indentationWidth = indentationWidth
		self.isNotesVisible = isNotesVisible
		self.isSelected = isSelected
		self.isDisclosureVisible = isDisclosureVisible
		self.rowIndentSize = rowIndentSize
		self.rowSpacingSize = rowSpacingSize
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorRowContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func isLayoutEqual(_ other: EditorRowContentConfiguration) -> Bool {
		return outlineNumberingStyle == other.outlineNumberingStyle
			&& indentationWidth == other.indentationWidth
			&& isDisclosureVisible == other.isDisclosureVisible
			&& isNotesVisible == other.isNotesVisible
			&& isSelected == other.isSelected
			&& rowIndentSize == other.rowIndentSize
			&& rowSpacingSize == other.rowSpacingSize
	}

	static func == (lhs: EditorRowContentConfiguration, rhs: EditorRowContentConfiguration) -> Bool {
		return lhs.rowID == rhs.rowID
			&& lhs.rowTopic == rhs.rowTopic
			&& lhs.rowNote == rhs.rowNote
			&& lhs.rowHasChildren == rhs.rowHasChildren
			&& lhs.rowIsExpanded == rhs.rowIsExpanded
			&& lhs.rowOutlineNumbering == rhs.rowOutlineNumbering
			&& lhs.rowCurrentLevel == rhs.rowCurrentLevel
			&& lhs.rowTrueLevel == rhs.rowTrueLevel
			&& lhs.rowIsComplete == rhs.rowIsComplete
			&& lhs.rowIsAnyParentComplete == rhs.rowIsAnyParentComplete
			&& lhs.rowSearchResultCoordinates == rhs.rowSearchResultCoordinates
			&& lhs.isSearching == rhs.isSearching
			&& lhs.outlineCheckSpellingWhileTyping == rhs.outlineCheckSpellingWhileTyping
			&& lhs.outlineCorrectSpellingAutomatically == rhs.outlineCorrectSpellingAutomatically
			&& lhs.isLayoutEqual(rhs)
	}

}

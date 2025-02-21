//
//  EditorRowContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import VinOutlineKit

struct EditorRowContentConfiguration: UIContentConfiguration {

	weak var delegate: EditorRowViewCellDelegate? = nil

	var row: Row? = nil
	var isSearching: Bool
	
	var numberingStyle: Outline.NumberingStyle?
	var indentationWidth: CGFloat
	var isDisclosureVisible: Bool
	var isNotesVisible: Bool
	var isSelected: Bool
	var rowIndentSize: DefaultsSize?
	var rowSpacingSize: DefaultsSize?
	
	init(row: Row,
		 isSearching: Bool,
		 numberingStyle: Outline.NumberingStyle?,
		 indentationWidth: CGFloat,
		 isDisclosureVisible: Bool,
		 isNotesVisible: Bool,
		 isSelected: Bool,
		 rowIndentSize: DefaultsSize?,
		 rowSpacingSize: DefaultsSize?) {
		self.row = row
		self.isSearching = isSearching
		self.numberingStyle = numberingStyle
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
		return numberingStyle == other.numberingStyle
			&& indentationWidth == other.indentationWidth
			&& isDisclosureVisible == other.isDisclosureVisible
			&& isNotesVisible == other.isNotesVisible
			&& isSelected == other.isSelected
			&& rowIndentSize == other.rowIndentSize
			&& rowSpacingSize == other.rowSpacingSize
	}
	
}

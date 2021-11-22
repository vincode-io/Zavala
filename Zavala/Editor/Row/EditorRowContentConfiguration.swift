//
//  EditorRowContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

struct EditorRowContentConfiguration: UIContentConfiguration {

	weak var delegate: EditorRowViewCellDelegate? = nil

	var row: Row? = nil
	var isSearching: Bool

	var indentationWidth: CGFloat
	var isDisclosureVisible: Bool
	var isNotesVisible: Bool
	
	init(row: Row, isSearching: Bool, indentationWidth: CGFloat, isDisclosureVisible: Bool,  isNotesVisible: Bool) {
		self.row = row
		self.isSearching = isSearching
		self.indentationWidth = indentationWidth
		self.isNotesVisible = isNotesVisible
		self.isDisclosureVisible = isDisclosureVisible
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorRowContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func isLayoutEqual(_ other: EditorRowContentConfiguration) -> Bool {
		return indentationWidth == other.indentationWidth && isDisclosureVisible == other.isDisclosureVisible && isNotesVisible == other.isNotesVisible
	}
	
}

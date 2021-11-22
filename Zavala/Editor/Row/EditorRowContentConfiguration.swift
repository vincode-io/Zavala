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

	var horizontalSizeClass: UIUserInterfaceSizeClass
	var isDisclosureVisible: Bool
	var isNotesVisible: Bool
	
	init(row: Row, isSearching: Bool, isDisclosureVisible: Bool,  isNotesVisible: Bool, horizontalSizeClass: UIUserInterfaceSizeClass) {
		self.row = row
		self.isSearching = isSearching
		self.isNotesVisible = isNotesVisible
		self.isDisclosureVisible = isDisclosureVisible
		self.horizontalSizeClass = horizontalSizeClass
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorRowContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func isLayoutEqual(_ other: EditorRowContentConfiguration) -> Bool {
		return horizontalSizeClass == other.horizontalSizeClass &&
		isDisclosureVisible == other.isDisclosureVisible &&
		isNotesVisible == other.isNotesVisible
	}
	
}

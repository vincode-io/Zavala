//
//  EditorTextRowContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

struct EditorTextRowContentConfiguration: UIContentConfiguration, Hashable {

	var row: Row? = nil
	weak var delegate: EditorTextRowViewCellDelegate? = nil

	var id: String
	var indentionLevel: Int
	var indentationWidth: CGFloat
	var isNotesHidden: Bool
	var isSearching: Bool
	var isChevronShowing: Bool
	
	init(row: Row, indentionLevel: Int, indentationWidth: CGFloat, isNotesHidden: Bool, isSearching: Bool) {
		self.row = row
		self.indentionLevel = indentionLevel
		self.indentationWidth = indentationWidth
		self.isNotesHidden = isNotesHidden
		self.isSearching = isSearching

		self.id = row.id
		self.isChevronShowing = row.rowCount > 0
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorTextRowContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(indentionLevel)
		hasher.combine(indentationWidth)
		hasher.combine(isNotesHidden)
		hasher.combine(isSearching)
		hasher.combine(isChevronShowing)
	}
	
	static func == (lhs: EditorTextRowContentConfiguration, rhs: EditorTextRowContentConfiguration) -> Bool {
		return lhs.id == rhs.id &&
			lhs.indentionLevel == rhs.indentionLevel &&
			lhs.indentationWidth == rhs.indentationWidth &&
			lhs.isNotesHidden == rhs.isNotesHidden &&
			lhs.isSearching == rhs.isSearching &&
			lhs.isChevronShowing == rhs.isChevronShowing
	}
	
}

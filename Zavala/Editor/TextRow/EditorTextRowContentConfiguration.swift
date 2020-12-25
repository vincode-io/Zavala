//
//  EditorTextRowContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

struct EditorTextRowContentConfiguration: UIContentConfiguration, Hashable {

	weak var row: TextRow? = nil
	weak var delegate: EditorTextRowViewCellDelegate? = nil

	var id: String
	var indentionLevel: Int
	var indentationWidth: CGFloat
	var isChevronShowing: Bool
	var isComplete: Bool
	var isAncestorComplete: Bool
	var topic: NSAttributedString
	// TODO: We need to include noteText here.
	
	init(row: TextRow, indentionLevel: Int, indentationWidth: CGFloat) {
		self.row = row
		self.indentionLevel = indentionLevel
		self.indentationWidth = indentationWidth
		
		self.id = row.id
		self.isChevronShowing = !(row.rows?.isEmpty ?? true)
		self.isComplete = row.isComplete ?? false
		self.isAncestorComplete = row.isAncestorComplete
		self.topic = row.topic ?? NSAttributedString(string: "")
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
		hasher.combine(isChevronShowing)
		hasher.combine(isComplete)
		hasher.combine(isAncestorComplete)
		hasher.combine(topic)
	}
	
	static func == (lhs: EditorTextRowContentConfiguration, rhs: EditorTextRowContentConfiguration) -> Bool {
		return lhs.id == rhs.id &&
			lhs.indentionLevel == rhs.indentionLevel &&
			lhs.indentationWidth == rhs.indentationWidth &&
			lhs.isChevronShowing == rhs.isChevronShowing &&
			lhs.isComplete == rhs.isComplete &&
			lhs.isAncestorComplete == rhs.isAncestorComplete &&
			lhs.topic.isEqual(to: rhs.topic)
	}
}

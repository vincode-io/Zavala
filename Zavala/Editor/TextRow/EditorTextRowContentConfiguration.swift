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

	var id: EntityID
	var indentionLevel: Int
	var indentationWidth: CGFloat
	var isNotesHidden: Bool
	var isChevronShowing: Bool
	var isComplete: Bool
	var isAncestorComplete: Bool
	var topic: NSAttributedString?
	var note: NSAttributedString?
	
	init(row: Row, indentionLevel: Int, indentationWidth: CGFloat, isNotesHidden: Bool) {
		self.row = row
		self.indentionLevel = indentionLevel
		self.indentationWidth = indentationWidth
		self.isNotesHidden = isNotesHidden
		
		self.id = row.id
		self.isChevronShowing = !(row.rows?.isEmpty ?? true)
		self.isComplete = row.isComplete ?? false
		self.isAncestorComplete = row.isAncestorComplete
		if let textRow = row.textRow {
			self.topic = textRow.topic
			self.note = textRow.note
		}
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
		hasher.combine(isChevronShowing)
		hasher.combine(isComplete)
		hasher.combine(isAncestorComplete)
		hasher.combine(topic)
		hasher.combine(note)
	}
	
	static func == (lhs: EditorTextRowContentConfiguration, rhs: EditorTextRowContentConfiguration) -> Bool {
		return lhs.id == rhs.id &&
			lhs.indentionLevel == rhs.indentionLevel &&
			lhs.indentationWidth == rhs.indentationWidth &&
			lhs.isNotesHidden == rhs.isNotesHidden &&
			lhs.isChevronShowing == rhs.isChevronShowing &&
			lhs.isComplete == rhs.isComplete &&
			lhs.isAncestorComplete == rhs.isAncestorComplete &&
			isAttributedStringsEqual(lhs: lhs.topic, rhs: rhs.topic) &&
			isAttributedStringsEqual(lhs: lhs.note, rhs: rhs.note)
	}
	
	static func isAttributedStringsEqual(lhs: NSAttributedString?, rhs: NSAttributedString?) -> Bool {
		if lhs == nil && rhs == nil {
			return true
		}
		if lhs != nil || rhs != nil {
			return false
		}
		return lhs!.isEqual(to: rhs!)
	}
}

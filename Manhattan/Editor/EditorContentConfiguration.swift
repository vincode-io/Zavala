//
//  EditorContentConfiguration.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

struct EditorContentConfiguration: UIContentConfiguration, Hashable {

	weak var headline: Headline? = nil
	weak var delegate: EditorCollectionViewCellDelegate? = nil

	var id: String
	var indentionLevel: Int
	var indentationWidth: CGFloat
	var isChevronShowing: Bool
	var isComplete: Bool
	var isAncestorComplete: Bool
	var attributedText: NSAttributedString
	
	init(headline: Headline, indentionLevel: Int, indentationWidth: CGFloat) {
		self.headline = headline
		self.indentionLevel = indentionLevel
		self.indentationWidth = indentationWidth
		
		self.id = headline.id
		self.isChevronShowing = !(headline.headlines?.isEmpty ?? true)
		self.isComplete = headline.isComplete ?? false
		self.isAncestorComplete = headline.isAncestorComplete ?? false
		self.attributedText = headline.attributedText ?? NSAttributedString(string: "")
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorContentView(configuration: self)
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
		hasher.combine(attributedText)
	}
	
	static func == (lhs: EditorContentConfiguration, rhs: EditorContentConfiguration) -> Bool {
		return lhs.id == rhs.id &&
			lhs.indentionLevel == rhs.indentionLevel &&
			lhs.indentationWidth == rhs.indentationWidth &&
			lhs.isChevronShowing == rhs.isChevronShowing &&
			lhs.isComplete == rhs.isComplete &&
			lhs.isAncestorComplete == rhs.isAncestorComplete &&
			lhs.attributedText.isEqual(to: rhs.attributedText)
	}
}

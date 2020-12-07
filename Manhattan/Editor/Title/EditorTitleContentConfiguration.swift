//
//  EditorTitleContentConfiguration.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton

struct EditorTitleContentConfiguration: UIContentConfiguration, Hashable {

	var outline: Outline
	weak var delegate: EditorTitleViewCellDelegate?
	
	init(outline: Outline) {
		self.outline = outline
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorTitleContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(outline.id)
		hasher.combine(outline.title)
	}
	
	static func == (lhs: EditorTitleContentConfiguration, rhs: EditorTitleContentConfiguration) -> Bool {
		return lhs.outline.id == rhs.outline.id &&
			lhs.outline.title == rhs.outline.title
	}
	
}

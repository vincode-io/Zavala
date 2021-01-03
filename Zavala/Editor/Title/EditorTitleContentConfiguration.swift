//
//  EditorTitleContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton

struct EditorTitleContentConfiguration: UIContentConfiguration, Hashable {

	var title: String?
	weak var delegate: EditorTitleViewCellDelegate?
	
	init(title: String?) {
		self.title = title
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorTitleContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(title)
	}
	
	static func == (lhs: EditorTitleContentConfiguration, rhs: EditorTitleContentConfiguration) -> Bool {
		return lhs.title == rhs.title
	}
	
}

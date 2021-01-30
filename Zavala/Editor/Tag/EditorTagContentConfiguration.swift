//
//  EditorTagContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit

struct EditorTagContentConfiguration: UIContentConfiguration, Hashable {

	var name: String?
	weak var delegate: EditorTagViewCellDelegate?
	
	init(name: String?) {
		self.name = name
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorTagContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
	
	static func == (lhs: EditorTagContentConfiguration, rhs: EditorTagContentConfiguration) -> Bool {
		return lhs.name == rhs.name
	}
	
}

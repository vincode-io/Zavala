//
//  EditorTagInputContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit

struct EditorTagInputContentConfiguration: UIContentConfiguration, Hashable {

	weak var delegate: EditorTagInputViewCellDelegate?
	
	func makeContentView() -> UIView & UIContentView {
		return EditorTagInputContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine("onlyone")
	}
	
	static func == (lhs: EditorTagInputContentConfiguration, rhs: EditorTagInputContentConfiguration) -> Bool {
		return true
	}
	
}

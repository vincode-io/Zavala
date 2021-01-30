//
//  EditorTagInputContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit
import Templeton

struct EditorTagInputContentConfiguration: UIContentConfiguration, Hashable {

	var outlineID: EntityID?
	weak var delegate: EditorTagInputViewCellDelegate?
	
	init(outlineID: EntityID?) {
		self.outlineID = outlineID
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorTagInputContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(outlineID)
	}
	
	static func == (lhs: EditorTagInputContentConfiguration, rhs: EditorTagInputContentConfiguration) -> Bool {
		return lhs.outlineID == rhs.outlineID
	}
	
}

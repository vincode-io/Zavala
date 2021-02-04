//
//  EditorTagAddContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 2/4/21.
//

import UIKit
import Templeton

struct EditorTagAddContentConfiguration: UIContentConfiguration, Hashable {

	var outlineID: EntityID?
	weak var delegate: EditorTagAddViewCellDelegate?
	
	init(outlineID: EntityID?) {
		self.outlineID = outlineID
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorTagAddContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(outlineID)
	}
	
	static func == (lhs: EditorTagAddContentConfiguration, rhs: EditorTagAddContentConfiguration) -> Bool {
		return lhs.outlineID == rhs.outlineID
	}
	
}

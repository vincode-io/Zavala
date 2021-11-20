//
//  EditorTagInputContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit
import Templeton

struct EditorTagInputContentConfiguration: UIContentConfiguration, Hashable {

	weak var delegate: EditorTagInputViewCellDelegate?
	let outineID: EntityID
	
	init(outlineID: EntityID) {
		self.outineID = outlineID
	}

	func makeContentView() -> UIView & UIContentView {
		return EditorTagInputContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(outineID)
	}
	
	static func == (lhs: EditorTagInputContentConfiguration, rhs: EditorTagInputContentConfiguration) -> Bool {
		return lhs.outineID == rhs.outineID
	}
	
}

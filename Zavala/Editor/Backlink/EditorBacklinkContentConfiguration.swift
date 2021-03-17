//
//  EditorBacklinkContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 3/16/21.
//

import UIKit

struct EditorBacklinkContentConfiguration: UIContentConfiguration, Hashable {

	var reference: NSAttributedString?
	
	init(reference: NSAttributedString?) {
		self.reference = reference
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorBacklinkContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(reference)
	}
	
	static func == (lhs: EditorBacklinkContentConfiguration, rhs: EditorBacklinkContentConfiguration) -> Bool {
		return NSAttributedString.isOptionalStringsEqual(lhs: lhs.reference, rhs: rhs.reference)
	}
	
}

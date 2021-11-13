//
//  EditorTagInputContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit
import Templeton

struct EditorTagInputContentConfiguration: UIContentConfiguration {

	weak var delegate: EditorTagInputViewCellDelegate?

	func makeContentView() -> UIView & UIContentView {
		return EditorTagInputContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

}

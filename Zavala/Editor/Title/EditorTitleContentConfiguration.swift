//
//  EditorTitleContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import VinOutlineKit

struct EditorTitleContentConfiguration: UIContentConfiguration {

	weak var outline: Outline?
	weak var delegate: EditorTitleViewCellDelegate?
	
	init(outline: Outline?) {
		self.outline = outline
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorTitleContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

}

//
//  EditorTitleContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit

struct EditorTitleContentConfiguration: UIContentConfiguration {

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

}

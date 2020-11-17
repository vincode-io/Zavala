//
//  EditorContentConfiguration.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit

struct EditorContentConfiguration: UIContentConfiguration, Hashable {

	weak var editorItem: EditorItem? = nil
	weak var delegate: EditorCollectionViewCellDelegate? = nil
	var indentationWidth: CGFloat? = nil
	
	func makeContentView() -> UIView & UIContentView {
		return EditorContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(editorItem)
	}
	
	static func == (lhs: EditorContentConfiguration, rhs: EditorContentConfiguration) -> Bool {
		return lhs.editorItem == rhs.editorItem
	}
}

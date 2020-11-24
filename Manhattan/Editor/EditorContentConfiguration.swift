//
//  EditorContentConfiguration.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

struct EditorContentConfiguration: UIContentConfiguration, Hashable {

	weak var headline: Headline? = nil
	weak var delegate: EditorCollectionViewCellDelegate? = nil

	var indentionLevel: Int
	var indentationWidth: CGFloat
	var isChevronShowing: Bool {
		return !(headline?.headlines?.isEmpty ?? true)
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(headline)
	}
	
	static func == (lhs: EditorContentConfiguration, rhs: EditorContentConfiguration) -> Bool {
		return lhs.headline == rhs.headline
	}
}

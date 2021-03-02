//
//  EditorTagAddViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 2/4/21.
//

import UIKit
import Templeton

protocol EditorTagAddViewCellDelegate: AnyObject {
	func editorTagAddAddTag()
}

class EditorTagAddViewCell: UICollectionViewCell {
	
	var outlineID: EntityID? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}

	weak var delegate: EditorTagAddViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}

	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		var content = EditorTagAddContentConfiguration(outlineID: outlineID).updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}

}

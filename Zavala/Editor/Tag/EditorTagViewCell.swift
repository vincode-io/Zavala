//
//  EditorTagViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit

protocol EditorTagViewCellDelegate: class {
	func editorTagDeleteTag(name: String)
}

class EditorTagViewCell: UICollectionViewCell {
    
	var name: String? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	weak var delegate: EditorTagViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		var content = EditorTagContentConfiguration(name: name).updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}
	
}

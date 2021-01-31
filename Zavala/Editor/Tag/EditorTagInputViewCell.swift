//
//  EditorTagInputViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit
import Templeton

protocol EditorTagInputViewCellDelegate: class {
	var editorTagInputUndoManager: UndoManager? { get }
	func editorTagInputLayoutEditor()
	func editorTagInputTextFieldDidBecomeActive()
}

class EditorTagInputViewCell: UICollectionViewCell {
	
	var outlineID: EntityID? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}

	weak var delegate: EditorTagInputViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}

	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		var content = EditorTagInputContentConfiguration(outlineID: outlineID).updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}

	func takeCursor() {
		guard let textField = (contentView as? EditorTagInputContentView)?.textField else { return }
		textField.becomeFirstResponder()
	}
	
}

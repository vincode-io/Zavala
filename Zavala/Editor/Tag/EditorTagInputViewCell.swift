//
//  EditorTagInputViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit
import VinOutlineKit

@MainActor
protocol EditorTagInputViewCellDelegate: AnyObject {
	var editorTagInputUndoManager: UndoManager? { get }
	var editorTagInputTags: [Tag]? { get }
	func editorTagInputLayoutEditor()
	func editorTagInputTextFieldDidBecomeActive()
	func editorTagInputTextFieldDidReturn()
	func editorTagInputTextFieldCreateTag(name: String)
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

		guard let outlineID else { return }
		var content = EditorTagInputContentConfiguration(outlineID: outlineID).updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}

	func takeCursor() {
		guard let textField = (contentView as? EditorTagInputContentView)?.inputPill.textField else { return }
		textField.becomeFirstResponder()
	}
	
}

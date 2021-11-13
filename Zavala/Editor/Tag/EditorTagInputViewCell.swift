//
//  EditorTagInputViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit
import Templeton

protocol EditorTagInputViewCellDelegate: AnyObject {
	var editorTagInputUndoManager: UndoManager? { get }
	var editorTagInputIsAddShowing: Bool { get }
	var editorTagInputTags: [Tag]? { get }
	func editorTagInputLayoutEditor()
	func editorTagInputTextFieldDidBecomeActive()
	func editorTagInputTextFieldShowAdd()
	func editorTagInputTextFieldHideAdd()
	func editorTagInputTextFieldCreateRow()
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
		var content = EditorTagInputContentConfiguration().updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}

	func takeCursor() {
		guard let textField = (contentView as? EditorTagInputContentView)?.textField else { return }
		textField.becomeFirstResponder()
	}
	
	func createTag() {
		guard let textField = (contentView as? EditorTagInputContentView)?.textField else { return }
		textField.createTag()
	}
	
}

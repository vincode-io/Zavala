//
//  EditorTagInputViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit

protocol EditorTagInputViewCellDelegate: class {
	var editorTagInputUndoManager: UndoManager? { get }
	func editorTagInputLayoutEditor()
	func editorTagInputTextFieldDidBecomeActive()
}

class EditorTagInputView: UICollectionViewCell {
	
}

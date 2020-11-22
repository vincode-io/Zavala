//
//  EditorCollectionViewCell.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit

protocol EditorCollectionViewCellDelegate: class {
	func textChanged(item: EditorItem, attributedText: NSAttributedString)
	func deleteHeadline(item: EditorItem)
	func createHeadline(item: EditorItem)
	func indent(item: EditorItem, attributedText: NSAttributedString)
	func outdent(item: EditorItem, attributedText: NSAttributedString)
	func moveUp(item: EditorItem)
	func moveDown(item: EditorItem)
}

class EditorCollectionViewCell: UICollectionViewListCell {

	weak var editorItem: EditorItem? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	weak var delegate: EditorCollectionViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
	
		var content = EditorContentConfiguration(indentionLevel: indentationLevel, indentationWidth: indentationWidth).updated(for: state)
		content.editorItem = editorItem
		content.delegate = delegate
		content.isChevronShowing = !accessories.isEmpty
		contentConfiguration = content
	}

}

extension EditorCollectionViewCell: TextCursorTarget {
	
	func restoreSelection(_ textRange: UITextRange) {
		guard let textView = (contentView as? EditorContentView)?.textView else { return }
		textView.becomeFirstResponder()
		textView.selectedTextRange = textRange
	}
	
	func moveToEnd() {
		guard let textView = (contentView as? EditorContentView)?.textView else { return }
		textView.becomeFirstResponder()
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
	}
	
}

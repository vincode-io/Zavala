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

	var editorItem: EditorItem? {
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
		guard let editorItem = editorItem else { return }
	
		if editorItem.children.isEmpty {
			accessories = []
		} else {
			accessories = [.outlineDisclosure(options: .init(style: .cell))]
		}
		
		var content = EditorContentConfiguration(editorItem: editorItem, indentionLevel: indentationLevel, indentationWidth: indentationWidth).updated(for: state)
		content.delegate = delegate
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

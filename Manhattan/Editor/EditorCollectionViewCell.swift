//
//  EditorCollectionViewCell.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/16/20.
//

import UIKit

protocol EditorCollectionViewCellDelegate: class {
	func newHeadline(item: EditorItem)
	func indent(item: EditorItem)
	func outdent(item: EditorItem)
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
		
		var content = EditorContentConfiguration().updated(for: state)
		content.editorItem = editorItem
		content.delegate = delegate
		
		if traitCollection.userInterfaceIdiom == .mac && accessories.isEmpty {
			content.indentationWidth = indentationWidth + 16
		}
		
		contentConfiguration = content
	}

	func takeCursor() {
		guard let textView = (contentView as? EditorContentView)?.textView else { return }
		textView.becomeFirstResponder()
		let endPosition = textView.endOfDocument
		textView.selectedTextRange = textView.textRange(from: endPosition, to: endPosition)
	}
	
}

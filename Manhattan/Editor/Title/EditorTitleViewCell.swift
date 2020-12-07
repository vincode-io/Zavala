//
//  EditorTitleViewCell.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton

protocol EditorTitleViewCellDelegate: class {
	var undoManager: UndoManager? { get }
	func invalidateLayout()
	func createHeadline()
}

class EditorTitleViewCell: UICollectionViewListCell {

	var outline: Outline? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	weak var delegate: EditorTitleViewCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		
		layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

		guard let outline = outline else { return }
		var content = EditorTitleContentConfiguration(outline: outline).updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}

}

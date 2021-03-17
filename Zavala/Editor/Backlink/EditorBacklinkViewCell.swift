//
//  EditorBacklinkViewCell.swift
//  Zavala
//
//  Created by Maurice Parker on 3/16/21.
//

import UIKit

class EditorBacklinkViewCell: UICollectionViewListCell {

	var reference: NSAttributedString? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
		let content = EditorBacklinkContentConfiguration(reference: reference).updated(for: state)
		contentConfiguration = content
	}


}

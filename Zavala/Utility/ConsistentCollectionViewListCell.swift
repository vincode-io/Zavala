//
//  ConsistentCollectionViewListCell.swift
//  Zavala
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit

class ConsistentCollectionViewListCell: UICollectionViewListCell {
	
	var insetBackground = false
	
	// We would always tint the image in white, except when the image is tinted
	// white in light mode, it isn't actually white. It is gray for some reason.
	var highlightImageInWhite = false
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		
		guard var contentConfig = contentConfiguration as? UIListContentConfiguration else { return }
		
		var backgroundConfig = UIBackgroundConfiguration.listSidebarCell().updated(for: state)

		if state.traitCollection.userInterfaceIdiom == .mac {
			backgroundConfig.cornerRadius = 5
			if insetBackground {
				backgroundConfig.backgroundInsets = NSDirectionalEdgeInsets(top: 2, leading: 9, bottom: 2, trailing: 9)
			}
		}
		
		if state.isSelected || state.isHighlighted {
			contentConfig.textProperties.color = .white
			contentConfig.secondaryTextProperties.color = .white
			if highlightImageInWhite {
				contentConfig.imageProperties.tintColor = .white
			}
			backgroundConfig.backgroundColor = UIColor.accentColor
		} else {
			contentConfig.textProperties.color = .label
			contentConfig.secondaryTextProperties.color = .label
			if highlightImageInWhite {
				contentConfig.imageProperties.tintColor = nil
			}
			backgroundConfig.backgroundColor = .clear
		}
		
		contentConfiguration = contentConfig
		backgroundConfiguration = backgroundConfig
	}
	
}

//
//  ConsistentCollectionViewListCell.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit

class ConsistentCollectionViewListCell : UICollectionViewListCell {
	
	var insetBackground = false
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		
		guard state.traitCollection.userInterfaceIdiom != .mac else {
			guard var backgroundConfig = backgroundConfiguration else { return }
			backgroundConfig.cornerRadius = 5
			if insetBackground {
				backgroundConfig.backgroundInsets = NSDirectionalEdgeInsets(top: 1, leading: 9, bottom: 1, trailing: 9)
			}
			backgroundConfiguration = backgroundConfig
			return
		}
		
		guard var contentConfig = contentConfiguration as? UIListContentConfiguration else { return }
		
		var backgroundConfig = UIBackgroundConfiguration.listSidebarCell().updated(for: state)

		if state.isSelected || state.isHighlighted {
			contentConfig.textProperties.color = .white
			contentConfig.secondaryTextProperties.color = .white
			contentConfig.imageProperties.tintColor = .white
			backgroundConfig.backgroundColor = AppAssets.accent
		} else {
			contentConfig.textProperties.color = .label
			contentConfig.secondaryTextProperties.color = .label
			contentConfig.imageProperties.tintColor = AppAssets.accent
		}
		
		contentConfiguration = contentConfig
		backgroundConfiguration = backgroundConfig
	}
	
}

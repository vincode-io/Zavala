//
//  ConsistentCollectionViewListCell.swift
//  Zavala
//
//  Created by Maurice Parker on 12/4/20.
//

import UIKit

class ConsistentCollectionViewListCell: UICollectionViewListCell {
	
	var insetBackground = false
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		
		guard var contentConfig = contentConfiguration as? UIListContentConfiguration else { return }
		
		var backgroundConfig = UIBackgroundConfiguration.listSidebarCell().updated(for: state)

		if state.traitCollection.userInterfaceIdiom == .mac {
			backgroundConfig.cornerRadius = 5
			if insetBackground {
				backgroundConfig.backgroundInsets = NSDirectionalEdgeInsets(top: 1, leading: 9, bottom: 1, trailing: 9)
			}
		}
		
		if state.isSelected || state.isHighlighted {
			contentConfig.textProperties.color = .white
			contentConfig.secondaryTextProperties.color = .white
			backgroundConfig.backgroundColor = UIColor.accentColor.withAlphaComponent(0.6)
		} else {
			contentConfig.textProperties.color = .label
			contentConfig.secondaryTextProperties.color = .label
			backgroundConfig.backgroundColor = .clear
		}
		
		contentConfiguration = contentConfig
		backgroundConfiguration = backgroundConfig
	}
	
}

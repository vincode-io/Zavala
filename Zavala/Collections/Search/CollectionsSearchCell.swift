//
//  CollectionsSearchCell.swift
//  Zavala
//
//  Created by Maurice Parker on 1/11/21.
//

import UIKit

protocol CollectionsSearchCellDelegate: AnyObject {
	func collectionsSearchDidBecomeActive()
	func collectionsSearchDidUpdate(searchText: String?)
}

class CollectionsSearchCell: UICollectionViewListCell {
	
	var searchText: String? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	weak var delegate: CollectionsSearchCellDelegate? {
		didSet {
			setNeedsUpdateConfiguration()
		}
	}
	
	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		
		var content = CollectionsSearchContentConfiguration(searchText: searchText).updated(for: state)
		content.delegate = delegate
		contentConfiguration = content
	}
	
	func setSearchField(searchText: String) {
		(contentView as? CollectionsSearchContentView)?.searchTextField.text = searchText
		(contentView as? CollectionsSearchContentView)?.searchTextField.becomeFirstResponder()
	}
	
	func clearSearchField() {
		(contentView as? CollectionsSearchContentView)?.searchTextField.text = nil
	}
	
}

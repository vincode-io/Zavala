//
//  CollectionsSearchContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 1/11/21.
//

import UIKit

struct CollectionsSearchContentConfiguration: UIContentConfiguration, Hashable {

	var searchText: String?
	weak var delegate: CollectionsSearchCellDelegate?
	
	init(searchText: String?) {
		self.searchText = searchText
	}
	
	func makeContentView() -> UIView & UIContentView {
		return CollectionsSearchContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(searchText)
	}
	
	static func == (lhs: CollectionsSearchContentConfiguration, rhs: CollectionsSearchContentConfiguration) -> Bool {
		return lhs.searchText == rhs.searchText
	}
	
}

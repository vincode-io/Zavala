//
//  SidebarSearchContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 1/11/21.
//

import UIKit

struct SidebarSearchContentConfiguration: UIContentConfiguration, Hashable {

	var searchText: String?
	weak var delegate: SidebarSearchCellDelegate?
	
	init(searchText: String?) {
		self.searchText = searchText
	}
	
	func makeContentView() -> UIView & UIContentView {
		return SidebarSearchContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(searchText)
	}
	
	static func == (lhs: SidebarSearchContentConfiguration, rhs: SidebarSearchContentConfiguration) -> Bool {
		return lhs.searchText == rhs.searchText
	}
	
}

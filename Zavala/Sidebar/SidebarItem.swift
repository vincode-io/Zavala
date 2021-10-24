//
//  SidebarItem.swift
//  Zavala
//
//  Created by Maurice Parker on 11/14/20.
//

import UIKit
import Templeton

final class SidebarItem: NSObject, NSCopying, Identifiable {
	
	enum ID: Hashable {
		case header(SidebarSection)
		case search
		case documentContainer(EntityID)
		
		var name: String? {
			if case .header(let section) = self {
				switch section {
				case .localAccount:
					return AccountType.local.name
				case .cloudKitAccount:
					return AccountType.cloudKit.name
				default:
					break
				}
			}
			return nil
		}
		
	}
	
	let id: SidebarItem.ID
	
	var entityID: EntityID? {
		if case .documentContainer(let entityID) = id {
			return entityID
		}
		return nil
	}
	
	init(id: ID) {
		self.id = id
	}
	
	static func searchSidebarItem() -> SidebarItem {
		return SidebarItem(id: .search)
	}
	
	static func sidebarItem(id: ID) -> SidebarItem {
		return SidebarItem(id: id)
	}
	
	static func sidebarItem(_ documentContainer: DocumentContainer) -> SidebarItem {
		let id = SidebarItem.ID.documentContainer(documentContainer.id)
		return SidebarItem(id: id)
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? SidebarItem else { return false }
		if self === other { return true }
		return id == other.id
	}
	
	override var hash: Int {
		var hasher = Hasher()
		hasher.combine(id)
		return hasher.finalize()
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		return self
	}
	
}

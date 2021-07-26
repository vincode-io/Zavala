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
	}
	
	let id: SidebarItem.ID
	let title: String?
	let image: UIImage?
	let count: Int?
	
	var entityID: EntityID? {
		if case .documentContainer(let entityID) = id {
			return entityID
		}
		return nil
	}
	
	init(id: ID, title: String?, image: UIImage?, count: Int?) {
		self.id = id
		self.title = title
		self.image = image
		self.count = count
	}
	
	static func searchSidebarItem() -> SidebarItem {
		return SidebarItem(id: .search, title: nil, image: nil, count: nil)
	}
	
	static func sidebarItem(title: String, id: ID) -> SidebarItem {
		return SidebarItem(id: id, title: title, image: nil, count: nil)
	}
	
	static func sidebarItem(_ documentContainer: DocumentContainer) -> SidebarItem {
		let id = SidebarItem.ID.documentContainer(documentContainer.id)
		return SidebarItem(id: id, title: documentContainer.name, image: documentContainer.image, count: documentContainer.itemCount)
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? SidebarItem else { return false }
		if self === other { return true }
		return id == other.id && title == other.title && count == other.count
	}
	
	override var hash: Int {
		var hasher = Hasher()
		hasher.combine(id)
		hasher.combine(title)
		hasher.combine(count)
		return hasher.finalize()
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		return self
	}
	
}

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
		case outlineProvider(EntityID)
	}
	
	let id: SidebarItem.ID
	let title: String?
	let image: UIImage?
	
	var entityID: EntityID? {
		if case .outlineProvider(let entityID) = id {
			return entityID
		}
		return nil
	}
	
	var isFolder: Bool {
		guard let entityID = entityID else { return false }
		switch entityID {
		case .folder(_, _):
			return true
		default:
			return false
		}
	}
	
	init(id: ID, title: String?, image: UIImage?) {
		self.id = id
		self.title = title
		self.image = image
	}
	
	static func sidebarItem(title: String, id: ID) -> SidebarItem {
		return SidebarItem(id: id, title: title, image: nil)
	}
	
	static func sidebarItem(_ outlineProvider: OutlineProvider) -> SidebarItem {
		let id = SidebarItem.ID.outlineProvider(outlineProvider.id)
		return SidebarItem(id: id, title: outlineProvider.name, image: outlineProvider.image)
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? SidebarItem else { return false }
		if self === other { return true }
		return id == other.id && title == other.title
	}
	
	override var hash: Int {
		var hasher = Hasher()
		hasher.combine(id)
		hasher.combine(title)
		return hasher.finalize()
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		return self
	}
	
}

//
//  CollectionsItem.swift
//  Zavala
//
//  Created by Maurice Parker on 11/14/20.
//

import UIKit
import Templeton

final class CollectionsItem: NSObject, NSCopying, Identifiable {
	
	enum ID: Hashable {
		case header(CollectionsSection)
		case search
		case documentContainer(EntityID)
		
		var accountType: AccountType? {
			if case .header(let section) = self {
				switch section {
				case .localAccount:
					return AccountType.local
				case .cloudKitAccount:
					return AccountType.cloudKit
				default:
					break
				}
			}
			return nil
		}
		
		var name: String? {
			return accountType?.name
		}
		
	}
	
	let id: CollectionsItem.ID
	
	var entityID: EntityID? {
		if case .documentContainer(let entityID) = id {
			return entityID
		}
		return nil
	}
	
	init(id: ID) {
		self.id = id
	}
	
	static func searchItem() -> CollectionsItem {
		return CollectionsItem(id: .search)
	}
	
	static func item(id: ID) -> CollectionsItem {
		return CollectionsItem(id: id)
	}
	
	static func item(_ documentContainer: DocumentContainer) -> CollectionsItem {
		let id = CollectionsItem.ID.documentContainer(documentContainer.id)
		return CollectionsItem(id: id)
	}

	override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? CollectionsItem else { return false }
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

extension Array where Element == CollectionsItem {
	
	func toContainers() -> [DocumentContainer] {
		return self.compactMap { item in
			if case .documentContainer(let entityID) = item.id {
				return AccountManager.shared.findDocumentContainer(entityID)
			}
			return nil
		}
	}
	
}

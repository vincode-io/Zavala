//
//  Search.swift
//  
//
//  Created by Maurice Parker on 1/12/21.
//

import UIKit
import CoreSpotlight

public final class Search: Identifiable, DocumentContainer {
	
	public var id: EntityID
	public var name: String? = VinOutlineKitStringAssets.search
	public var image: UIImage?
	public var account: Account? = nil

	public var itemCount: Int? {
		return nil
	}
	
	public var searchText: String
	
	private var searchQuery: CSSearchQuery?

	public init(searchText: String) {
		self.id = .search(searchText)
		self.searchText = searchText
	}
	
	public func documents(completion: @escaping (Result<[Document], Error>) -> Void) {
		searchQuery?.cancel()

		var searchableItems = [CSSearchableItem]()

		guard searchText.count > 2 else {
			completion(.success([Document]()))
			return
		}
		
		let queryString = "title == \"*\(searchText)*\"c || textContent == \"*\(searchText)*\"c"
		searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)

		searchQuery?.foundItemsHandler = { items in
			searchableItems.append(contentsOf: items)
		}

		searchQuery?.completionHandler = { [weak self] error in
			DispatchQueue.main.async {
				guard let self else {
					completion(.success([Document]()))
					return
				}
				if let error {
					completion(.failure(error))
				} else {
					completion(.success(self.toDocuments(searchableItems)))
				}
			}
		}

		searchQuery?.start()
	}
	
	deinit {
		searchQuery?.cancel()
	}
	
}

// MARK: Helpers

private extension Search {
	
	func toDocuments(_ searchItems: [CSSearchableItem]) -> [Document] {
		return searchItems.compactMap {
			if let entityID = EntityID(description: $0.uniqueIdentifier) {
				if let document = AccountManager.shared.findDocument(entityID) {
					return document
				}
			}
			return nil
		}
	}
	
}
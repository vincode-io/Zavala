//
//  Search.swift
//  
//
//  Created by Maurice Parker on 1/12/21.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif
import CoreSpotlight

public final class Search: Identifiable, DocumentContainer {
	
	public var id: EntityID
	public var name: String? = VinOutlineKitStringAssets.search
	public var partialName: String? = VinOutlineKitStringAssets.search

	#if canImport(UIKit)
	public var image: UIImage?
	#endif
	public var account: Account? = nil

	public var itemCount: Int? {
		return nil
	}

	public var children: [DocumentContainer] = []

	public var searchText: String
	
	private var searchQuery: CSSearchQuery?

	public var documents: [Document] {
		get async throws {
			searchQuery?.cancel()
			
			guard searchText.count > 2 else {
				return []
			}
			
			return try await withCheckedThrowingContinuation { continuation in
				var  foundItems = [CSSearchableItem]()
				
				let queryString = "title == \"*\(searchText)*\"c || textContent == \"*\(searchText)*\"c"
				searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
				
				searchQuery?.foundItemsHandler = { items in
					foundItems.append(contentsOf: items)
				}
				
				searchQuery?.completionHandler = { error in
					if let error {
						continuation.resume(throwing: error)
					} else {
						let documents = foundItems.compactMap {
							if let entityID = EntityID(description: $0.uniqueIdentifier) {
								if let document = AccountManager.shared.findDocument(entityID) {
									return document
								}
							}
							return nil
						}
						continuation.resume(returning: documents)
					}
				}
				
				searchQuery?.start()
			}
		}
		
	}


	public init(searchText: String) {
		self.id = .search(searchText)
		self.searchText = searchText
	}
	
	public func hasDecendent(_ entityID: EntityID) -> Bool {
		return false
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

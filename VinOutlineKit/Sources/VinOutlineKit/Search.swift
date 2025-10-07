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
	
	public let id: EntityID
	public var name: String? = .search
	public var partialName: String? = .search

	#if canImport(UIKit)
	public var image: UIImage?
	#endif
	public var account: Account? = nil

	public var itemCount: Int? {
		return nil
	}

	public var ancestors: [DocumentContainer] = []
	public var children: [DocumentContainer] = []

	public var searchText: String
	
	private var searchQuery: CSSearchQuery?

	public var documents: [Document] {
		get async throws {
			searchQuery?.cancel()
			
			guard searchText.count > 2 else {
				return []
			}
			
			let queryString = "** == \"*\(searchText)*\"c"
			searchQuery = CSSearchQuery(queryString: queryString, queryContext: nil)

			var documents = [Document]()
			
			for try await result in searchQuery!.results {
				if let entityID = EntityID(description: result.item.uniqueIdentifier) {
					if let document = accountManager!.findDocument(entityID) {
						documents.append(document)
					}
				}
			}

			return documents
		}
	}

	private weak var accountManager: AccountManager?

	public init(accountManager: AccountManager, searchText: String) {
		self.accountManager = accountManager
		self.id = .search(searchText)
		self.searchText = searchText
	}
	
	public func hasDecendent(_ entityID: EntityID) -> Bool {
		return false
	}

}

// MARK: Helpers

private extension Search {
	
	func toDocuments(_ searchItems: [CSSearchableItem]) -> [Document] {
		return searchItems.compactMap {
			if let entityID = EntityID(description: $0.uniqueIdentifier) {
				if let document = accountManager!.findDocument(entityID) {
					return document
				}
			}
			return nil
		}
	}
	
}

//
//  FolderAppEntityQuery.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import CoreSpotlight
import VinOutlineKit

@available(iOS 27.0, *)
struct FolderAppEntityQuery: EntityStringQuery, IndexedEntityQuery, ZavalaAppIntent {

	@MainActor
	func entities(for entityIDs: [FolderAppEntity.ID]) async -> [FolderAppEntity] {
		resume()

		var entities = [FolderAppEntity]()
		for entityID in entityIDs {
			guard case .tagDocuments(let accountID, let tagID) = entityID,
				  let account = appDelegate.accountManager.findAccount(accountID: accountID),
				  let tag = account.tags?.first(where: { $0.id == tagID }) else { continue }
			entities.append(FolderAppEntity(tag: tag, account: account))
		}

		await suspend()
		return entities
	}

	@MainActor
	func entities(matching string: String) async -> [FolderAppEntity] {
		resume()
		let entities = Self.allFolders().filter { $0.name.localizedStandardContains(string) }
		await suspend()
		return entities
	}

	@MainActor
	func suggestedEntities() async -> [FolderAppEntity] {
		resume()
		let entities = Self.allFolders()
		await suspend()
		return entities
	}

	// MARK: IndexedEntityQuery

	func reindexEntities(for identifiers: [FolderAppEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
		let entities = await entities(for: identifiers)
		try await CSSearchableIndex.default().indexAppEntities(entities)
	}

	func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
		let entities = await suggestedEntities()
		try await CSSearchableIndex.default().indexAppEntities(entities)
	}

	// MARK: Helpers

	@MainActor
	static func allFolders() -> [FolderAppEntity] {
		return appDelegate.accountManager.sortedActiveAccounts.flatMap { account in
			(account.tags ?? []).map { FolderAppEntity(tag: $0, account: account) }
		}
	}

}

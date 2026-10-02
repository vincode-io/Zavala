//
//  NoteAppEntityQuery.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import CoreSpotlight
import VinOutlineKit

@available(iOS 27.0, *)
struct NoteAppEntityQuery: EntityStringQuery, IndexedEntityQuery, ZavalaAppIntent {

	@MainActor
	func entities(for entityIDs: [NoteAppEntity.ID]) async -> [NoteAppEntity] {
		resume()
		let entities = entityIDs
			.compactMap { findOutline($0) }
			.filter { $0.isLocked != true }
			.map { NoteAppEntity(outline: $0) }
		await suspend()
		return entities
	}

	@MainActor
	func entities(matching string: String) async -> [NoteAppEntity] {
		resume()
		let entities = availableOutlines()
			.filter { $0.title?.localizedStandardContains(string) == true }
			.map { NoteAppEntity(outline: $0) }
		await suspend()
		return entities
	}

	@MainActor
	func suggestedEntities() async -> [NoteAppEntity] {
		resume()
		let entities = availableOutlines().map { NoteAppEntity(outline: $0) }
		await suspend()
		return entities
	}

	// MARK: IndexedEntityQuery

	// Notes are indexed by associating them with their Outline's Spotlight item, so reindexing goes through
	// DocumentIndexer rather than indexing the notes on their own, which would put each Outline in Spotlight twice.

	func reindexEntities(for identifiers: [NoteAppEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
		await reindexOutlines(identifiers)
	}

	func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
		await reindexOutlines(nil)
	}

	/// Reindexes the Outlines with the given IDs, or all of them when there aren't any IDs.
	@MainActor
	private func reindexOutlines(_ identifiers: [NoteAppEntity.ID]?) async {
		resume()
		let documents = if let identifiers {
			identifiers.compactMap { appDelegate.accountManager.findDocument($0) }
		} else {
			appDelegate.accountManager.activeDocuments
		}
		await NoteIndexer.reindex(documents)
		await suspend()
	}

	// MARK: Helpers

	@MainActor
	private func availableOutlines() -> [Outline] {
		return appDelegate.accountManager.activeDocuments
			.compactMap(\.outline)
			.filter { $0.isLocked != true }
			.sorted { ($0.title ?? "").localizedStandardCompare($1.title ?? "") == .orderedAscending }
	}

}

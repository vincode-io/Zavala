//
//  FolderAppEntity.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import CoreSpotlight
import VinOutlineKit

/// Maps a Zavala Tag to the Notes domain folder schema. Hierarchical tags (e.g. "Work/Projects")
/// are represented using the parent folder relationship.
@available(iOS 27.0, *)
@AppEntity(schema: .notes.folder)
struct FolderAppEntity: IndexedEntity {
	static let isAssistantOnly = true
	static let defaultQuery = FolderAppEntityQuery()

	/// Uses the `tagDocuments` EntityID so that both the Account and the Tag can be found from it.
	let id: EntityID

	var name: String
	var parentFolder: FolderAppEntity?
	var account: AccountAppEntity?

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: name)
	}

	// MARK: IndexedEntity

	/// Siri and Apple Intelligence find folders through this index, e.g. "Create an outline in Tasks". The folders
	/// aren't hidden from Spotlight because hideInSpotlight keeps an entity out of the index entirely, which also
	/// hides it from Siri.
	var attributeSet: CSSearchableItemAttributeSet {
		let attributeSet = defaultAttributeSet
		attributeSet.title = name
		return attributeSet
	}

	@MainActor
	init(tag: Tag, account: Account) {
		self.id = .tagDocuments(account.id.accountID, tag.id)
		self.name = tag.partialName
		self.account = AccountAppEntity(account: account)

		if let parentName = tag.parentName, let parentTag = account.findTag(name: parentName) {
			self.parentFolder = FolderAppEntity(tag: parentTag, account: account)
		}
	}
}

//
//  AccountAppEntity.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import VinOutlineKit

/// Maps a Zavala Account to the Notes domain account schema.
@available(iOS 27.0, *)
@AppEntity(schema: .notes.account)
struct AccountAppEntity {
	static let isAssistantOnly = true
	static let defaultQuery = AccountAppEntityQuery()

	let id: EntityID

	var name: String

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: name)
	}

	@MainActor
	init(account: Account) {
		self.id = account.id
		self.name = account.name
	}
}

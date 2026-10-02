//
//  AccountAppEntityQuery.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import VinOutlineKit

@available(iOS 27.0, *)
struct AccountAppEntityQuery: EntityQuery, ZavalaAppIntent {

	@MainActor
	func entities(for entityIDs: [AccountAppEntity.ID]) async -> [AccountAppEntity] {
		resume()
		let entities = entityIDs
			.compactMap { appDelegate.accountManager.findAccount(accountID: $0.accountID) }
			.map { AccountAppEntity(account: $0) }
		await suspend()
		return entities
	}

	@MainActor
	func suggestedEntities() async -> [AccountAppEntity] {
		resume()
		let entities = appDelegate.accountManager.sortedActiveAccounts.map { AccountAppEntity(account: $0) }
		await suspend()
		return entities
	}

}

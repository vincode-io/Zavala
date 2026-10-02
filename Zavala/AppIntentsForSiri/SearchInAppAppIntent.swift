//
//  SearchInAppAppIntent.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents

/// Shows Zavala's search results for the given text, e.g. "Search Zavala for groceries".
@available(iOS 27.0, *)
@AppIntent(schema: .system.searchInApp)
struct SearchInAppAppIntent: ShowInAppSearchResultsIntent, ZavalaAppIntent {
	static let isAssistantOnly = true
	static let searchScopes: [StringSearchScope] = [.general]

	var criteria: StringSearchCriteria

	@MainActor
	func perform() async throws -> some IntentResult {
		await showSearch(criteria.term)
		return .result()
	}
}

//
//  FindOutlinesAppIntent.swift
//  Zavala
//
//  Created by Maurice Parker on 3/14/26.
//

import Foundation
import AppIntents
import VinOutlineKit

struct FindOutlinesEntityQuery: EntityPropertyQuery, ZavalaAppIntent {

	// MARK: - EntityQuery

	func entities(for entityIDs: [OutlineAppEntity.ID]) async -> [OutlineAppEntity] {
		await resume()

		var results = [OutlineAppEntity]()
		for entityID in entityIDs {
			if let entity = await MainActor.run(body: {
				guard let outline = appDelegate.accountManager.findDocument(entityID)?.outline,
					  outline.isLocked != true else { return nil as OutlineAppEntity? }
				return OutlineAppEntity(outline: outline)
			}) {
				results.append(entity)
			}
		}

		await suspend()
		return results
	}

	@MainActor
	func suggestedEntities() async throws -> [OutlineAppEntity] {
		resume()
		let entities = appDelegate.accountManager.activeDocuments
			.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending })
			.compactMap(\.outline)
			.filter({ $0.isLocked != true })
			.map({ OutlineAppEntity(outline: $0) })
		await suspend()
		return entities
	}

	// MARK: - EntityPropertyQuery

	nonisolated(unsafe) static var properties = QueryProperties {
		Property(\OutlineAppEntity.$title) {
			EqualToComparator { OutlineComparator.titleEquals($0) }
			NotEqualToComparator { OutlineComparator.titleNotEquals($0) }
			ContainsComparator { OutlineComparator.titleContains($0) }
		}
		Property(\OutlineAppEntity.$ownerName) {
			EqualToComparator { OutlineComparator.ownerNameEquals($0) }
			NotEqualToComparator { OutlineComparator.ownerNameNotEquals($0) }
			ContainsComparator { OutlineComparator.ownerNameContains($0) }
		}
		Property(\OutlineAppEntity.$ownerEmail) {
			EqualToComparator { OutlineComparator.ownerEmailEquals($0) }
			NotEqualToComparator { OutlineComparator.ownerEmailNotEquals($0) }
			ContainsComparator { OutlineComparator.ownerEmailContains($0) }
		}
		Property(\OutlineAppEntity.$ownerURL) {
			EqualToComparator { OutlineComparator.ownerURLEquals($0) }
			NotEqualToComparator { OutlineComparator.ownerURLNotEquals($0) }
			ContainsComparator { OutlineComparator.ownerURLContains($0) }
		}
		Property(\OutlineAppEntity.$created) {
			LessThanComparator { OutlineComparator.createdBefore($0) }
			GreaterThanComparator { OutlineComparator.createdAfter($0) }
		}
		Property(\OutlineAppEntity.$updated) {
			LessThanComparator { OutlineComparator.updatedBefore($0) }
			GreaterThanComparator { OutlineComparator.updatedAfter($0) }
		}
		Property(\OutlineAppEntity.$tags) {
			ContainsComparator { OutlineComparator.tagsContain($0) }
		}
		Property(\OutlineAppEntity.$accountType) {
			EqualToComparator { OutlineComparator.accountTypeEquals($0) }
			NotEqualToComparator { OutlineComparator.accountTypeNotEquals($0) }
		}
		Property(\OutlineAppEntity.$url) {
			EqualToComparator { OutlineComparator.urlEquals($0) }
		}
	}

	nonisolated(unsafe) static var sortingOptions = SortingOptions {
		SortableBy(\OutlineAppEntity.$title)
		SortableBy(\OutlineAppEntity.$ownerName)
		SortableBy(\OutlineAppEntity.$created)
		SortableBy(\OutlineAppEntity.$updated)
	}

	func entities(
		matching comparators: [OutlineComparator],
		mode: ComparatorMode,
		sortedBy: [Sort<OutlineAppEntity>],
		limit: Int?
	) async throws -> [OutlineAppEntity] {
		await resume()

		var entities = await MainActor.run {
			appDelegate.accountManager.documents.compactMap(\.outline).filter { outline in
				guard outline.isLocked != true else { return false }
				let matches = comparators.map { $0.matches(outline) }
				switch mode {
				case .and:
					return matches.allSatisfy { $0 }
				case .or:
					return matches.contains { $0 }
				}
			}.map { OutlineAppEntity(outline: $0) }
		}

		if let primarySort = sortedBy.first {
			entities.sort { lhs, rhs in
				let ascending = primarySort.order == .ascending
				switch primarySort.by {
				case \OutlineAppEntity.$title:
					let result = (lhs.title ?? "").localizedCaseInsensitiveCompare(rhs.title ?? "")
					return ascending ? result == .orderedAscending : result == .orderedDescending
				case \OutlineAppEntity.$ownerName:
					let result = (lhs.ownerName ?? "").localizedCaseInsensitiveCompare(rhs.ownerName ?? "")
					return ascending ? result == .orderedAscending : result == .orderedDescending
				case \OutlineAppEntity.$created:
					let lhsDate = lhs.created ?? .distantPast
					let rhsDate = rhs.created ?? .distantPast
					return ascending ? lhsDate < rhsDate : lhsDate > rhsDate
				case \OutlineAppEntity.$updated:
					let lhsDate = lhs.updated ?? .distantPast
					let rhsDate = rhs.updated ?? .distantPast
					return ascending ? lhsDate < rhsDate : lhsDate > rhsDate
				default:
					return false
				}
			}
		} else {
			entities.sort { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending }
		}

		await suspend()

		if let limit {
			return Array(entities.prefix(limit))
		}
		return entities
	}

}

// MARK: - OutlineComparator

enum OutlineComparator: Sendable {
	case titleEquals(String?)
	case titleNotEquals(String?)
	case titleContains(String)
	case ownerNameEquals(String?)
	case ownerNameNotEquals(String?)
	case ownerNameContains(String)
	case ownerEmailEquals(String?)
	case ownerEmailNotEquals(String?)
	case ownerEmailContains(String)
	case ownerURLEquals(String?)
	case ownerURLNotEquals(String?)
	case ownerURLContains(String)
	case createdBefore(Date)
	case createdAfter(Date)
	case updatedBefore(Date)
	case updatedAfter(Date)
	case tagsContain(String)
	case accountTypeEquals(AccountTypeAppEnum?)
	case accountTypeNotEquals(AccountTypeAppEnum?)
	case urlEquals(URL?)

	@MainActor
	func matches(_ outline: Outline) -> Bool {
		switch self {
		case .titleEquals(let value):
			return outline.title?.localizedCaseInsensitiveCompare(value ?? "") == .orderedSame
		case .titleNotEquals(let value):
			return outline.title?.localizedCaseInsensitiveCompare(value ?? "") != .orderedSame
		case .titleContains(let value):
			return outline.title?.localizedStandardContains(value) == true
		case .ownerNameEquals(let value):
			return outline.ownerName?.localizedCaseInsensitiveCompare(value ?? "") == .orderedSame
		case .ownerNameNotEquals(let value):
			return outline.ownerName?.localizedCaseInsensitiveCompare(value ?? "") != .orderedSame
		case .ownerNameContains(let value):
			return outline.ownerName?.localizedStandardContains(value) == true
		case .ownerEmailEquals(let value):
			return outline.ownerEmail?.localizedCaseInsensitiveCompare(value ?? "") == .orderedSame
		case .ownerEmailNotEquals(let value):
			return outline.ownerEmail?.localizedCaseInsensitiveCompare(value ?? "") != .orderedSame
		case .ownerEmailContains(let value):
			return outline.ownerEmail?.localizedStandardContains(value) == true
		case .ownerURLEquals(let value):
			return outline.ownerURL?.localizedCaseInsensitiveCompare(value ?? "") == .orderedSame
		case .ownerURLNotEquals(let value):
			return outline.ownerURL?.localizedCaseInsensitiveCompare(value ?? "") != .orderedSame
		case .ownerURLContains(let value):
			return outline.ownerURL?.localizedStandardContains(value) == true
		case .createdBefore(let date):
			guard let created = outline.created else { return false }
			return created < date
		case .createdAfter(let date):
			guard let created = outline.created else { return false }
			return created > date
		case .updatedBefore(let date):
			guard let updated = outline.updated else { return false }
			return updated < date
		case .updatedAfter(let date):
			guard let updated = outline.updated else { return false }
			return updated > date
		case .tagsContain(let value):
			return outline.tags.contains { $0.name.localizedStandardContains(value) }
		case .accountTypeEquals(let value):
			if outline.account?.type == .cloudKit {
				return value == .iCloud
			} else {
				return value == .onMyDevice
			}
		case .accountTypeNotEquals(let value):
			if outline.account?.type == .cloudKit {
				return value != .iCloud
			} else {
				return value != .onMyDevice
			}
		case .urlEquals(let value):
			return outline.id.url == value
		}
	}
}

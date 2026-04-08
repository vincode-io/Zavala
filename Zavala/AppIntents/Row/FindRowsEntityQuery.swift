//
//  FindRowsAppIntent.swift
//  Zavala
//
//  Created by Maurice Parker on 3/14/26.
//

import Foundation
import AppIntents
import VinOutlineKit
import VinUtility

struct FindRowsEntityQuery: EntityPropertyQuery, ZavalaAppIntent {

	// MARK: - EntityQuery

	func entities(for entityIDs: [RowAppEntity.ID]) async throws -> [RowAppEntity] {
		await resume()

		var results = [RowAppEntity]()
		for entityID in entityIDs {
			let entity = await MainActor.run(body: { () -> RowAppEntity? in
				guard let outline = appDelegate.accountManager.findDocument(entityID)?.outline,
					  outline.isLocked != true else { return nil }
				outline.load()
				defer { Task { await outline.unload() } }
				guard let row = outline.findRow(id: entityID.rowUUID) else { return nil }
				return RowAppEntity(row: row)
			})
			if let entity {
				results.append(entity)
			}
		}

		await suspend()
		return results
	}

	@MainActor
	func suggestedEntities() async throws -> [RowAppEntity] {
		return []
	}

	// MARK: - EntityPropertyQuery

	nonisolated(unsafe) static var properties = QueryProperties {
		Property(\RowAppEntity.$topic) {
			EqualToComparator { RowComparator.topicEquals($0) }
			NotEqualToComparator { RowComparator.topicNotEquals($0) }
			ContainsComparator { RowComparator.topicContains($0) }
		}
		Property(\RowAppEntity.$note) {
			EqualToComparator { RowComparator.noteEquals($0) }
			NotEqualToComparator { RowComparator.noteNotEquals($0) }
			ContainsComparator { RowComparator.noteContains($0) }
		}
		Property(\RowAppEntity.$complete) {
			EqualToComparator { RowComparator.completeEquals($0) }
			NotEqualToComparator { RowComparator.completeNotEquals($0) }
		}
		Property(\RowAppEntity.$expanded) {
			EqualToComparator { RowComparator.expandedEquals($0) }
			NotEqualToComparator { RowComparator.expandedNotEquals($0) }
		}
		Property(\RowAppEntity.$level) {
			EqualToComparator { RowComparator.levelEquals($0) }
			LessThanComparator { RowComparator.levelLessThan($0) }
			LessThanOrEqualToComparator { RowComparator.levelLessThanOrEqual($0) }
			GreaterThanComparator { RowComparator.levelGreaterThan($0) }
			GreaterThanOrEqualToComparator { RowComparator.levelGreaterThanOrEqual($0) }
		}
		Property(\RowAppEntity.$outline) {
			EqualToComparator { RowComparator.outlineEquals($0) }
		}
		Property(\RowAppEntity.$url) {
			EqualToComparator { RowComparator.urlEquals($0) }
		}
	}

	nonisolated(unsafe) static var sortingOptions = SortingOptions {
		SortableBy(\RowAppEntity.$rowOrder)
		SortableBy(\RowAppEntity.$topic)
		SortableBy(\RowAppEntity.$complete)
		SortableBy(\RowAppEntity.$level)
	}

	func entities(
		matching comparators: [RowComparator],
		mode: ComparatorMode,
		sortedBy: [Sort<RowAppEntity>],
		limit: Int?
	) async throws -> [RowAppEntity] {
		await resume()

		var entities = [RowAppEntity]()

		// If a URL comparator is present, use direct lookup instead of scanning all documents
		if let url = comparators.urlValue {
			if let entity = await MainActor.run(body: { findRowByURL(url, comparators: comparators, mode: mode) }) {
				entities.append(entity)
			}
		} else if let outlineEntityID = comparators.outlineEntityIDValue {
			// Use findDocument for direct lookup instead of scanning every outline
			await MainActor.run {
				guard let outline = appDelegate.accountManager.findDocument(outlineEntityID)?.outline,
					  outline.isLocked != true else { return }
				outline.load()
				let otherComparators = comparators.filter { !$0.isOutlineEntityIDComparator }
				if otherComparators.isEmpty {
					collectAllRows(from: outline.rows, into: &entities)
				} else {
					collectMatchingRows(from: outline.rows, comparators: otherComparators, mode: mode, into: &entities)
				}
			}
			if let outline = await MainActor.run(body: { appDelegate.accountManager.findDocument(outlineEntityID)?.outline }) {
				await outline.unload()
			}
		} else {
			let documents = await MainActor.run {
				appDelegate.accountManager.documents
			}

			for document in documents {
				await MainActor.run {
					guard let outline = document.outline else { return }
					outline.load()
					guard outline.isLocked != true else { return }
					collectMatchingRows(from: outline.rows, comparators: comparators, mode: mode, into: &entities)
				}
				if let outline = await document.outline {
					await outline.unload()
				}
			}
		}

		// Assign row order based on the collection order (outline order, top to bottom)
		for (index, _) in entities.enumerated() {
			entities[index].rowOrder = index
		}

		if let primarySort = sortedBy.first {
			switch primarySort.by {
			case \RowAppEntity.$rowOrder:
				if primarySort.order == .descending {
					entities.reverse()
				}
			default:
				entities.sort { lhs, rhs in
					let ascending = primarySort.order == .ascending
					switch primarySort.by {
					case \RowAppEntity.$topic:
						let result = (lhs.topic ?? "").localizedCaseInsensitiveCompare(rhs.topic ?? "")
						return ascending ? result == .orderedAscending : result == .orderedDescending
					case \RowAppEntity.$complete:
						let lhsVal = lhs.complete ?? false
						let rhsVal = rhs.complete ?? false
						if lhsVal == rhsVal { return false }
						return ascending ? !lhsVal : lhsVal
					case \RowAppEntity.$level:
						let lhsLevel = lhs.level ?? 0
						let rhsLevel = rhs.level ?? 0
						return ascending ? lhsLevel < rhsLevel : lhsLevel > rhsLevel
					default:
						return false
					}
				}
			}
		} else {
			entities.sort { ($0.topic ?? "").localizedCaseInsensitiveCompare($1.topic ?? "") == .orderedAscending }
		}

		await suspend()

		if let limit {
			return Array(entities.prefix(limit))
		}
		return entities
	}

}

// MARK: - Helpers

private extension FindRowsEntityQuery {

	@MainActor
	func findRowByURL(_ url: URL, comparators: [RowComparator], mode: ComparatorMode) -> RowAppEntity? {
		guard let entityID = EntityID(url: url),
			  let outline = appDelegate.accountManager.findDocument(entityID)?.outline,
			  outline.isLocked != true,
			  let row = appDelegate.accountManager.findRow(entityID) else {
			return nil
		}

		let entity = RowAppEntity(row: row)

		// Apply any remaining non-URL comparators
		let otherComparators = comparators.filter { !$0.isURLComparator }
		guard !otherComparators.isEmpty else { return entity }

		let matches = otherComparators.map { $0.matches(entity) }
		switch mode {
		case .and:
			return matches.allSatisfy({ $0 }) ? entity : nil
		case .or:
			// In OR mode, the URL match already qualifies
			return entity
		}
	}

	@MainActor
	func collectAllRows(from rows: [Row], into result: inout [RowAppEntity]) {
		for row in rows {
			result.append(RowAppEntity(row: row))
			collectAllRows(from: row.rows, into: &result)
		}
	}

	@MainActor
	func collectMatchingRows(from rows: [Row], comparators: [RowComparator], mode: ComparatorMode, into result: inout [RowAppEntity]) {
		for row in rows {
			let entity = RowAppEntity(row: row)
			let matches = comparators.map { $0.matches(entity) }
			let isMatch: Bool
			switch mode {
			case .and:
				isMatch = matches.allSatisfy { $0 }
			case .or:
				isMatch = matches.contains { $0 }
			}
			if isMatch {
				result.append(entity)
			}
			collectMatchingRows(from: row.rows, comparators: comparators, mode: mode, into: &result)
		}
	}

}

// MARK: - RowComparator

private extension [RowComparator] {

	var outlineEntityIDValue: EntityID? {
		for comparator in self {
			if case .outlineEquals(let outline) = comparator {
				return outline?.id
			}
		}
		return nil
	}

	var urlValue: URL? {
		for comparator in self {
			if case .urlEquals(let url) = comparator {
				return url
			}
		}
		return nil
	}

}

enum RowComparator: Sendable {
	case topicEquals(String?)
	case topicNotEquals(String?)
	case topicContains(String)
	case noteEquals(String?)
	case noteNotEquals(String?)
	case noteContains(String)
	case completeEquals(Bool?)
	case completeNotEquals(Bool?)
	case expandedEquals(Bool?)
	case expandedNotEquals(Bool?)
	case levelEquals(Int?)
	case levelLessThan(Int?)
	case levelLessThanOrEqual(Int?)
	case levelGreaterThan(Int?)
	case levelGreaterThanOrEqual(Int?)
	case outlineEquals(OutlineAppEntity?)
	case urlEquals(URL?)

	var isOutlineEntityIDComparator: Bool {
		if case .outlineEquals = self { return true }
		return false
	}

	var isURLComparator: Bool {
		if case .urlEquals = self { return true }
		return false
	}

	func matches(_ entity: RowAppEntity) -> Bool {
		switch self {
		case .topicEquals(let value):
			return entity.topic?.localizedCaseInsensitiveCompare(value ?? "") == .orderedSame
		case .topicNotEquals(let value):
			return entity.topic?.localizedCaseInsensitiveCompare(value ?? "") != .orderedSame
		case .topicContains(let value):
			return entity.topic?.localizedStandardContains(value) == true
		case .noteEquals(let value):
			return entity.note?.localizedCaseInsensitiveCompare(value ?? "") == .orderedSame
		case .noteNotEquals(let value):
			return entity.note?.localizedCaseInsensitiveCompare(value ?? "") != .orderedSame
		case .noteContains(let value):
			return entity.note?.localizedStandardContains(value) == true
		case .completeEquals(let value):
			return entity.complete == value
		case .completeNotEquals(let value):
			return entity.complete != value
		case .expandedEquals(let value):
			return entity.expanded == value
		case .expandedNotEquals(let value):
			return entity.expanded != value
		case .levelEquals(let value):
			return entity.level == value
		case .levelLessThan(let value):
			guard let level = entity.level, let value else { return false }
			return level < value
		case .levelLessThanOrEqual(let value):
			guard let level = entity.level, let value else { return false }
			return level <= value
		case .levelGreaterThan(let value):
			guard let level = entity.level, let value else { return false }
			return level > value
		case .levelGreaterThanOrEqual(let value):
			guard let level = entity.level, let value else { return false }
			return level >= value
		case .outlineEquals(let value):
			return entity.outline?.id == value?.id
		case .urlEquals(let value):
			return entity.url == value
		}
	}
}

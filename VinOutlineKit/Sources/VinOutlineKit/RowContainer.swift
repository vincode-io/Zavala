//
//  RowContainer.swift
//
//
//  Created by Maurice Parker on 11/22/20.
//

import Foundation
import OrderedCollections
import VinXML

@MainActor
public protocol RowContainer: AnyObject {
	var outline: Outline? { get }
	var entityID: EntityID { get }
	var rows: [Row] { get }
	var rowCount: Int { get }

	// Legacy rowOrder for backward compatibility during migration
	var ancestorRowOrder: OrderedSet<String>? { get set }
	var rowOrder: OrderedSet<String>? { get set }
}

public extension RowContainer {

	/// The parent ID for children of this container.
	/// Returns the row's ID if this is a Row, or nil if this is an Outline.
	var containerParentID: String? {
		return (self as? Row)?.id
	}

	func firstIndexOfRow(_ row: Row) -> Int? {
		// Use fractional indexing: find position in sorted children
		guard let outline else { return nil }
		let children = outline.childRows(of: containerParentID)
		return children.firstIndex(where: { $0.id == row.id })
	}

	func containsRow(_ row: Row) -> Bool {
		// Check if row's parentID matches this container
		return row.parentID == containerParentID
	}

	func insertRow(_ row: Row, at index: Int) {
		guard let outline else { return }

		// Legacy: Update rowOrder for backward compatibility
		if outline.isCloudKit && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}

		if rowOrder == nil {
			rowOrder = OrderedSet<String>()
		}

		let insertIndex = min(index, rowOrder?.count ?? 0)
		rowOrder?.insert(row.id, at: insertIndex)

		// Fractional indexing: Calculate order between siblings
		let siblings = outline.childRows(of: containerParentID)
		let beforeOrder: String? = index > 0 && index <= siblings.count ? siblings[index - 1].order : nil
		let afterOrder: String? = index < siblings.count ? siblings[index].order : nil

		row.order = FractionalIndex.between(beforeOrder, afterOrder)
		row.parentID = containerParentID

		// Add to keyedRows
		if outline.keyedRows == nil {
			outline.keyedRows = [String: Row]()
		}
		outline.keyedRows?[row.id] = row

		// Set the row's parent reference
		row.parent = self

		outline.requestCloudKitUpdates(for: [entityID, row.entityID])

		// Check if rebalancing is needed
		outline.rebalanceChildrenIfNeeded(parentID: containerParentID)
	}

	func removeRow(_ row: Row) {
		guard let outline else { return }

		// Legacy: Update rowOrder for backward compatibility
		if outline.isCloudKit && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}

		rowOrder?.remove(row.id)
		outline.keyedRows?.removeValue(forKey: row.id)

		outline.requestCloudKitUpdates(for: [entityID, row.entityID])
	}

	func appendRow(_ row: Row) {
		guard let outline else { return }

		// Legacy: Update rowOrder for backward compatibility
		if outline.isCloudKit && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}

		if rowOrder == nil {
			rowOrder = OrderedSet<String>()
		}

		rowOrder?.append(row.id)

		// Fractional indexing: Calculate order after the last sibling
		let siblings = outline.childRows(of: containerParentID)
		let lastOrder = siblings.last?.order

		row.order = FractionalIndex.between(lastOrder, nil)
		row.parentID = containerParentID

		// Add to keyedRows
		if outline.keyedRows == nil {
			outline.keyedRows = [String: Row]()
		}
		outline.keyedRows?[row.id] = row

		// Set the row's parent reference
		row.parent = self

		outline.requestCloudKitUpdates(for: [entityID, row.entityID])

		// Check if rebalancing is needed
		outline.rebalanceChildrenIfNeeded(parentID: containerParentID)
	}


	func importRows(outline: Outline, rowNodes: [VinXML.XMLNode], images: [String:  Data]?) {
		for rowNode in rowNodes {
			let topicMarkdown = rowNode.attributes["text"]
			let noteMarkdown = rowNode.attributes["_note"]

			let row = Row(outline: outline)
			row.importRow(topicMarkdown: topicMarkdown, noteMarkdown: noteMarkdown, images: images)

			if rowNode.attributes["_status"] == "checked" {
				row.isComplete = true
			}

			appendRow(row)

			if let rowNodes = rowNode["outline"] {
				row.importRows(outline: outline, rowNodes: rowNodes, images: images)
			}
		}
	}

}

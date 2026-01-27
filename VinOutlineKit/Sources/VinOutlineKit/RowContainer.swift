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
	var rows: [Row] { get }
	var rowCount: Int { get }
}

public extension RowContainer {

	/// The parent ID for children of this container.
	/// Returns the row's ID if this is a Row, or nil if this is an Outline.
	var containerParentID: String? {
		return (self as? Row)?.id
	}

	func firstIndexOfRow(_ row: Row) -> Int? {
		return rows.firstIndex(where: { $0.id == row.id })
	}

	func containsRow(_ row: Row) -> Bool {
		return rows.contains(where: { $0.id == row.id })
	}

	func insertRow(_ row: Row, at index: Int) {
		guard let outline else { return }

		// Calculate order between siblings using stored rows array
		let beforeOrder: String? = index > 0 && index <= rows.count ? rows[index - 1].order : nil
		let afterOrder: String? = index < rows.count ? rows[index].order : nil

		row.order = FractionalIndex.between(beforeOrder, afterOrder)
		row.parentID = containerParentID
		row.parent = self

		// Insert into the rows array at the correct position
		if let selfRow = self as? Row {
			selfRow.rows.insert(row, at: index)
		} else if let selfOutline = self as? Outline {
			selfOutline.rows.insert(row, at: index)
		}

		// Add to outline's index
		outline.addToIndex(row)

		outline.requestCloudKitUpdates(for: [row.entityID])

		// Check if rebalancing is needed
		outline.rebalanceChildrenIfNeeded(parentID: containerParentID)
	}

	func removeRow(_ row: Row) {
		guard let outline else { return }

		// Remove from the rows array
		if let selfRow = self as? Row {
			selfRow.rows.removeAll { $0.id == row.id }
		} else if let selfOutline = self as? Outline {
			selfOutline.rows.removeAll { $0.id == row.id }
		}

		// Remove from outline's index (including all descendants)
		outline.removeFromIndex(row)

		outline.requestCloudKitUpdates(for: [row.entityID])
	}

	func appendRow(_ row: Row) {
		guard let outline else { return }

		// Calculate order after the last sibling using stored rows array
		let lastOrder = rows.last?.order

		row.order = FractionalIndex.between(lastOrder, nil)
		row.parentID = containerParentID
		row.parent = self

		// Append to the rows array
		if let selfRow = self as? Row {
			selfRow.rows.append(row)
		} else if let selfOutline = self as? Outline {
			selfOutline.rows.append(row)
		}

		// Add to outline's index
		outline.addToIndex(row)

		outline.requestCloudKitUpdates(for: [row.entityID])

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

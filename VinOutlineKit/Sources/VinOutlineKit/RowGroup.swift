//
//  RowGroup.swift
//
//
//  Created by Maurice Parker on 2/26/21.
//

import Foundation
import OrderedCollections

public class RowGroup: Codable {

	let row: RowCoder
	let childRows: [RowCoder]
	let images: [String: [ImageCoder]]

	private enum CodingKeys: String, CodingKey {
		case row
		case childRows
		case images
	}

	@MainActor
	public init(_ row: Row) {
		self.row = row.toCoder()

		var childRows = [Row]()
		var images = [String: [Image]]()

		images[row.id] = row.images

		func keyedRowsVisitor(_ visited: Row) {
			childRows.append(visited)
			images[visited.id] = visited.images
			visited.rows.forEach { $0.visit(visitor: keyedRowsVisitor) }
		}

		row.rows.forEach { $0.visit(visitor: keyedRowsVisitor(_:)) }

		self.childRows = childRows.map { $0.toCoder() }

		var imageCoders = [String: [ImageCoder]]()
		for (rowID, images) in images {
			imageCoders[rowID] = images.map { $0.toCoder() }
		}
		self.images = imageCoders
	}

	@MainActor
	public func attach(to outline: Outline) -> Row {
		var idMap = [String: String]()
		var newChildRows = [Row]()
		var newImages = [String: [Image]]()

		let newRow = Row(coder: row).duplicate(newOutline: outline)
		idMap[row.id] = newRow.id

		for childRow in childRows {
			let newChildRow = Row(coder: childRow).duplicate(newOutline: outline)
			idMap[childRow.id] = newChildRow.id
			newChildRows.append(newChildRow)
		}

		for (rowID, images) in images {
			guard let newRowID = idMap[rowID] else { continue }
			newImages[newRowID] = images.map {
				return Image(coder: $0).duplicate(outline: outline, accountID: outline.id.accountID, documentUUID: outline.id.documentUUID, rowUUID: newRowID)
			}
		}

		outline.beginCloudKitBatchRequest()

		// Update parentID references to use new IDs and add to index
		for newChildRow in newChildRows {
			if let oldParentID = newChildRow.parentID, let newParentID = idMap[oldParentID] {
				newChildRow.parentID = newParentID
			}
			outline.addToIndex(newChildRow)
			outline.requestCloudKitUpdate(for: newChildRow.entityID)
		}

		for (newRowID, newImages) in newImages {
			outline.updateImages(rowID: newRowID, images: newImages)
		}

		outline.endCloudKitBatchRequest()

		// Update the main row's parentID if needed (will be overwritten by caller's insertRow)
		if let oldParentID = newRow.parentID, let newParentID = idMap[oldParentID] {
			newRow.parentID = newParentID
		}

		// Build the local hierarchy for the returned row and its descendants.
		// Group child rows by their parentID and assign to parent's rows array.
		var childrenByParent = [String: [Row]]()
		for newChildRow in newChildRows {
			if let parentID = newChildRow.parentID {
				childrenByParent[parentID, default: []].append(newChildRow)
			}
		}

		// Recursively assign children to their parents
		func assignChildren(to row: Row) {
			if let children = childrenByParent[row.id] {
				row.rows = children.sorted { $0.order < $1.order }
				for child in row.rows {
					child.parent = row
					assignChildren(to: child)
				}
			}
		}
		assignChildren(to: newRow)

		// Note: The main row is NOT added to the index here - that happens when
		// the caller inserts it into the outline using insertRow/appendRow

		return newRow
	}

	public func asData() throws -> Data {
		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary
		return try encoder.encode(self)
	}

	public static func fromData(_ data: Data) throws -> RowGroup {
		let decoder = PropertyListDecoder()
		return try decoder.decode(RowGroup.self, from: data)
	}

}

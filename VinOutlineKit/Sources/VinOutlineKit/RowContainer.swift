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
	
	var ancestorRowOrder: OrderedSet<String>? { get set }
	var rowOrder: OrderedSet<String>? { get set }
}

public extension RowContainer {

	func firstIndexOfRow(_ row: Row) -> Int? {
		return rowOrder?.firstIndex(of: row.id)
	}

	func containsRow(_ row: Row) -> Bool {
		return rowOrder?.contains(row.id) ?? false
	}

	func insertRow(_ row: Row, at: Int) {
		if outline?.isCloudKit ?? false && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}

		if rowOrder == nil {
			rowOrder = OrderedSet<String>()
		}

		if outline?.keyedRows == nil {
			outline?.keyedRows = [String: Row]()
		}

		rowOrder?.insert(row.id, at: at)
		outline?.keyedRows?[row.id] = row

		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}

	func removeRow(_ row: Row) {
		if outline?.isCloudKit ?? false && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}

		rowOrder?.remove(row.id)
		outline?.keyedRows?.removeValue(forKey: row.id)
		
		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}

	func appendRow(_ row: Row) {
		if outline?.isCloudKit ?? false && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}

		if rowOrder == nil {
			rowOrder = OrderedSet<String>()
		}
		
		if outline?.keyedRows == nil {
			outline?.keyedRows = [String: Row]()
		}
		
		rowOrder?.append(row.id)
		outline?.keyedRows?[row.id] = row

		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
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

//
//  RowGroup.swift
//  
//
//  Created by Maurice Parker on 2/26/21.
//

import Foundation

public class RowGroup: Codable {
	
	public var row: Row
	var childRows: [Row]

	private enum CodingKeys: String, CodingKey {
		case row
		case childRows
	}
	
	public init(_ row: Row) {
		self.row = row
		self.childRows = [Row]()
		
		func keyedRowsVisitor(_ visited: Row) {
			childRows.append(visited)
			visited.rows.forEach { $0.visit(visitor: keyedRowsVisitor) }
		}
		row.rows.forEach { $0.visit(visitor: keyedRowsVisitor(_:)) }
	}

	public func attach(to outline: Outline) -> Row {
		var idMap = [String: String]()
		var newChildRows = [Row]()
		
		for childRow in childRows {
			let newChildRow = childRow.duplicate(newOutline: outline)
			idMap[childRow.id] = newChildRow.id
			newChildRows.append(newChildRow)
		}
		
		if outline.keyedRows == nil {
			outline.keyedRows = [String: Row]()
		}
		
		outline.beginCloudKitBatchRequest()

		for newChildRow in newChildRows {
			var newChildRowRowOrder = [String]()
			for oldRowOrder in newChildRow.rowOrder {
				newChildRowRowOrder.append(idMap[oldRowOrder]!)
			}
			
			newChildRow.rowOrder = newChildRowRowOrder
			outline.keyedRows?[newChildRow.id] = newChildRow
			outline.requestCloudKitUpdate(for: newChildRow.entityID)
		}
		
		outline.endCloudKitBatchRequest()
		
		let newRow = row.duplicate(newOutline: outline)
		newRow.parent = row.parent
		var newRowRowOrder = [String]()
		for newRowOrder in newRow.rowOrder {
			newRowRowOrder.append(idMap[newRowOrder]!)
		}
		newRow.rowOrder = newRowRowOrder

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

//
//  Created by Maurice Parker on 2/7/24.
//

import Foundation
import OrderedCollections

public extension Outline {

	func loadRowFileData(_ data: Data) {
		let decoder = PropertyListDecoder()

		let outlineRows: OutlineRows
		do {
			outlineRows = try decoder.decode(OutlineRows.self, from: data)
		} catch {
			logger.error("Rows read deserialization failed: \(error.localizedDescription, privacy: .public)")
			return
		}

		// Build the row index from decoded data
		var tempIndex = [String: Row]()
		for (key, rowCoder) in outlineRows.keyedRows {
			let row = Row(coder: rowCoder)
			row.outline = self
			tempIndex[key] = row
		}

		// Check if migration to fractional indexing is needed
		let needsMigration = tempIndex.values.contains { $0.order.isEmpty }
		if needsMigration {
			migrateToFractionalIndexing(rowIndex: tempIndex, topLevelRowOrder: outlineRows.rowOrder)
		}

		// Set the row index and rebuild the hierarchy
		rowIndex = tempIndex
		rebuildRowsHierarchy()

		rowsFileDidLoad()
	}

	func buildRowFileData() -> Data? {
		// Collect all rows from the row index
		var keyedRowCoders = [String: RowCoder]()
		for (key, row) in rowIndex {
			keyedRowCoders[key] = row.toCoder()
		}

		// Write empty rowOrder arrays - ordering is now handled by fractional indexing on each Row
		let outlineRows = OutlineRows(keyedRows: keyedRowCoders)

		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		var rowsData: Data
		do {
			rowsData = try encoder.encode(outlineRows)
		} catch {
			logger.error("Rows save serialization failed: \(error.localizedDescription, privacy: .public)")
			return nil
		}

		return rowsData
	}

	func loadImageFileData(_ data: Data) {
		let decoder = PropertyListDecoder()
		let outlineImageCoders: [String: [ImageCoder]]
		do {
			outlineImageCoders = try decoder.decode([String: [ImageCoder]].self, from: data)
		} catch {
			logger.error("Images read deserialization failed: \(error.localizedDescription, privacy: .public)")
			return
		}

		var outlineImages = [String: [Image]]()
		for (key, imageCoders) in outlineImageCoders {
			outlineImages[key] = imageCoders.map{ Image(coder: $0) }
		}

		// We probably shoudld be trying to update the UI when this happens.
		outline?.images = outlineImages
	}

	func buildImageFileData() -> Data? {
		guard let images, !images.isEmpty else {
			imagesFile?.delete()
			return nil
		}

		var imageCoders = [String: [ImageCoder]]()
		for (key, images) in images {
			imageCoders[key] = images.map{ $0.toCoder() }
		}

		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		var imagesData: Data
		do {
			imagesData = try encoder.encode(imageCoders)
		} catch {
			logger.error("Images save serialization failed: \(error.localizedDescription, privacy: .public)")
			return nil
		}

		return imagesData
	}

	// MARK: - Migration

	/// Migrate from rowOrder-based ordering to fractional indexing.
	/// This walks the tree using the old rowOrder arrays and assigns order/parentID values.
	private func migrateToFractionalIndexing(rowIndex: [String: Row], topLevelRowOrder: [String]) {
		logger.info("Migrating local outline to fractional indexing: \(self.title ?? .noTitle)")


		func assignOrders(parentID: String?, rowIDs: [String]) {
			let orders = FractionalIndex.initial(count: rowIDs.count)
			for (index, rowID) in rowIDs.enumerated() {
				guard let row = rowIndex[rowID] else { continue }
				row.order = orders.isEmpty ? FractionalIndex.between(nil, nil) : orders[index]
				row.parentID = parentID

				requestCloudKitUpdate(for: row.entityID)

				// Recursively process children using the old migrationRowOrder
				let childIDs = Array(row.migrationRowOrder ?? [])
				if !childIDs.isEmpty {
					assignOrders(parentID: rowID, rowIDs: childIDs)
				}
				// Clear the migration data after processing
				row.migrationRowOrder = nil
			}
		}

		beginCloudKitBatchRequest()

		assignOrders(parentID: nil, rowIDs: topLevelRowOrder)
		
		requestCloudKitUpdate(for: id)
		endCloudKitBatchRequest()

		// Mark file as dirty to save the migrated data
		rowsFile?.markAsDirty()
	}

}

struct OldRow: Decodable {

	var row: RowCoder?

	private enum CodingKeys: String, CodingKey {
		case type
		case textRow
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		row = try container.decode(RowCoder.self, forKey: .textRow)
	}

}

struct OutlineRows: Codable {
	let fileVersion = 4
	var ancestorRowOrder: [String]?
	var rowOrder: [String]
	var keyedRows: [String: RowCoder]

	private enum CodingKeys: String, CodingKey {
		case fileVersion
		case ancestorRowOrder
		case rowOrder
		case keyedRows
	}

	public init(keyedRows: [String: RowCoder]) {
		ancestorRowOrder = nil
		rowOrder = []
		self.keyedRows = keyedRows
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let fileVersion = (try? container.decode(Int.self, forKey: .fileVersion)) ?? 1

		let allRows: [RowCoder]

		switch fileVersion {
		case 1:
			if let rowOrder = try? container.decode([EntityID].self, forKey: .rowOrder) {
				self.rowOrder = rowOrder.map { $0.rowUUID}
			} else {
				self.rowOrder = [String]()
			}
			if let entityKeyedRows = try? container.decode([EntityID: OldRow].self, forKey: .keyedRows) {
				allRows = Array(entityKeyedRows.values).compactMap { $0.row }
			} else {
				allRows = []
			}
		case 2:
			if let rowOrder = try? container.decode([String].self, forKey: .rowOrder) {
				self.rowOrder = rowOrder
			} else {
				self.rowOrder = [String]()
			}
			if let rows = try? container.decode([OldRow].self, forKey: .keyedRows) {
				allRows = rows.compactMap { $0.row }
			} else {
				allRows = []
			}
		case 3, 4:
			// Version 3 and 4 have the same structure, but 4 includes fractional indexing fields in RowCoder
			if let ancestorRowOrder = try? container.decode([String].self, forKey: .ancestorRowOrder) {
				self.ancestorRowOrder = ancestorRowOrder
			}
			if let rowOrder = try? container.decode([String].self, forKey: .rowOrder) {
				self.rowOrder = rowOrder
			} else {
				self.rowOrder = [String]()
			}
			if let rows = try? container.decode([RowCoder].self, forKey: .keyedRows) {
				allRows = rows
			} else {
				allRows = []
			}
		default:
			fatalError("Unrecognized Row File Version")
		}

		self.keyedRows = allRows.reduce([String: RowCoder]()) { result, row in
			var mutableResult = result
			mutableResult[row.id] = row
			return mutableResult
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(fileVersion, forKey: .fileVersion)
		try container.encode(ancestorRowOrder, forKey: .ancestorRowOrder)
		try container.encode(rowOrder, forKey: .rowOrder)
		try container.encode(Array(keyedRows.values), forKey: .keyedRows)
	}
}

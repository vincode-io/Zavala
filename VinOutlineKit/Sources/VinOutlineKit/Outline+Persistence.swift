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

		if let ancestorRowOrder = outlineRows.ancestorRowOrder {
			self.ancestorRowOrder = OrderedSet(ancestorRowOrder)
		}
		
		self.rowOrder = OrderedSet(outlineRows.rowOrder)
		
		var keyedRows = [String: Row]()
		for (key, rowCoder) in outlineRows.keyedRows {
			keyedRows[key] = Row(coder: rowCoder)
		}
		
		self.keyedRows = keyedRows
		rowsFileDidLoad()
	}
	
	func buildRowFileData() -> Data? {
		var keyedRowCoders = [String: RowCoder]()
		for (key, row) in keyedRows ?? [:] {
			keyedRowCoders[key] = row.toCoder()
		}
		
		let outlineRows = OutlineRows(ancestorRowOrder: outline?.ancestorRowOrder, rowOrder: rowOrder ?? [], keyedRows: keyedRowCoders)

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
	let fileVersion = 3
	var ancestorRowOrder: [String]?
	var rowOrder: [String]
	var keyedRows: [String: RowCoder]

	private enum CodingKeys: String, CodingKey {
		case fileVersion
		case ancestorRowOrder
		case rowOrder
		case keyedRows
	}
	
	public init(ancestorRowOrder: OrderedSet<String>?, rowOrder: OrderedSet<String>, keyedRows: [String: RowCoder]) {
		if let ancestorRowOrder {
			self.ancestorRowOrder = Array(ancestorRowOrder)
		}
		self.rowOrder = Array(rowOrder)
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
		case 3:
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

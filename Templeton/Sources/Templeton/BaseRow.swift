//
//  BaseRow.swift
//  
//
//  Created by Maurice Parker on 12/26/20.
//

import Foundation

public class BaseRow: NSObject, NSCopying, OPMLImporter, Identifiable {
	
	public var parent: RowContainer?
	public var shadowTableIndex: Int?

	public var id: String
	public var syncID: String?
	public var isExpanded: Bool
	public internal(set) var rows: [Row] {
		get {
			guard let outline = self.outline else { return [Row]() }
			return rowOrder.compactMap { outline.keyedRows?[$0] }
		}
		set {
			guard let outline = self.outline else { return }
			
			outline.beginCloudKitBatchRequest()
			outline.requestCloudKitUpdate(for: entityID)
			
			for id in rowOrder {
				outline.keyedRows?.removeValue(forKey: id)
				outline.requestCloudKitUpdate(for: entityID)
			}

			var order = [String]()
			for row in newValue {
				order.append(row.id)
				outline.keyedRows?[row.id] = row
				outline.requestCloudKitUpdate(for: row.entityID)
			}
			rowOrder = order
			
			outline.endCloudKitBatchRequest()
		}
	}
	
	public var rowCount: Int {
		return rowOrder.count
	}

	weak var outline: Outline? {
		didSet {
			if let outline = outline {
				_entityID = .row(outline.id.accountID, outline.id.documentUUID, id)
			}
		}
	}
	
	var rowOrder: [String]
	var images: [Image]? {
		get {
			return nil
		}
		set {
			
		}
	}

	var isAncestorComplete: Bool {
		if let parentRow = parent as? Row {
			return parentRow.isComplete || parentRow.isAncestorComplete
		}
		return false
	}

	var isPartOfSearchResult = false {
		didSet {
			guard isPartOfSearchResult else { return }
			
			var parentRow = parent as? Row
			while (parentRow != nil) {
				parentRow!.isPartOfSearchResult = true
				parentRow = parentRow?.parent as? Row
			}
		}
	}
	
	private var _entityID: EntityID?
	var entityID: EntityID {
		guard let entityID = _entityID else {
			fatalError("Missing EntityID for row")
		}
		return entityID
	}
	
	public override init() {
		self.id = ""
		self.isExpanded = true
		self.rowOrder = [String]()
	}
	
	public func findImage(id: EntityID) -> Image? {
		return nil
	}
	
	public func saveImage(_ image: Image) {
	}

	public func deleteImage(id: EntityID) {
	}
	
	public func firstIndexOfRow(_ row: Row) -> Int? {
		return rows.firstIndex(of: row)
	}
	
	public func containsRow(_ row: Row) -> Bool {
		return rows.contains(row)
	}
	
	public func insertRow(_ row: Row, at: Int) {
		rowOrder.insert(row.id, at: at)
		outline?.keyedRows?[row.id] = row

		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}

	public func removeRow(_ row: Row) {
		rowOrder.removeFirst(object: row.id)
		outline?.keyedRows?.removeValue(forKey: row.id)
		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}

	public func appendRow(_ row: Row) {
		rowOrder.append(row.id)
		outline?.keyedRows?[row.id] = row

		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}

	public override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? Self else { return false }
		if self === other { return true }
		return id == other.id
	}
	
	public override var hash: Int {
		var hasher = Hasher()
		hasher.combine(id)
		return hasher.finalize()
	}
	
	public func copy(with zone: NSZone? = nil) -> Any {
		return self
	}
	
}

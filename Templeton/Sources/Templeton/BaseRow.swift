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
	public var isExpanded: Bool?
	public var rows: [Row]? {
		get {
			if let rowOrder = rowOrder, let rowData = rowData {
				return rowOrder.compactMap { rowData[$0] }
			} else {
				return nil
			}
		}
		set {
			if let rows = newValue {
				var order = [String]()
				var data = [String: Row]()
				for row in rows {
					order.append(row.id)
					data[row.id] = row
				}
				rowOrder = order
				rowData = data
			} else {
				rowOrder = nil
				rowData = nil
			}
		}
	}
	
	var rowOrder: [String]?
	var rowData: [String: Row]?

	public override init() {
		self.id = ""
	}
	
	func insertRow(_ row: Row, at: Int) {
		if rowOrder == nil {
			rowOrder = [String]()
		}
		if rowData == nil {
			rowData = [String: Row]()
		}
		rowOrder?.insert(row.id, at: at)
		rowData?[row.id] = row
	}

	func removeRow(_ row: Row) {
		rowOrder?.removeFirst(object: row.id)
		rowData?.removeValue(forKey: row.id)
	}

	func appendRow(_ row: Row) {
		if rowOrder == nil {
			rowOrder = [String]()
		}
		if rowData == nil {
			rowData = [String: Row]()
		}
		rowOrder?.append(row.id)
		rowData?[row.id] = row
	}

	public func markdown(indentLevel: Int = 0) -> String {
		fatalError("markdown not implemented")
	}
	
	public func opml(indentLevel: Int = 0) -> String {
		fatalError("opml not implemented")
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

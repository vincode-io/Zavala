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

	public var id: EntityID
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
				var order = [EntityID]()
				var data = [EntityID: Row]()
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
	
	public var account: Account? {
		return AccountManager.shared.findAccount(accountID: id.accountID)
	}
	
	public var outline: Outline? {
		let document = account?.findDocument(documentUUID: id.documentUUID)
		if case .outline(let outline) = document {
			return outline
		}
		return nil
	}
	
	var rowOrder: [EntityID]?
	var rowData: [EntityID: Row]?

	public override init() {
		self.id = .row(0, "", "")
	}
	
	public func insertRow(_ row: Row, at: Int) {
		if rowOrder == nil {
			rowOrder = [EntityID]()
		}
		if rowData == nil {
			rowData = [EntityID: Row]()
		}
		rowOrder?.insert(row.id, at: at)
		rowData?[row.id] = row
	}

	public func removeRow(_ row: Row) {
		rowOrder?.removeFirst(object: row.id)
		rowData?.removeValue(forKey: row.id)
	}

	public func appendRow(_ row: Row) {
		if rowOrder == nil {
			rowOrder = [EntityID]()
		}
		if rowData == nil {
			rowData = [EntityID: Row]()
		}
		rowOrder?.append(row.id)
		rowData?[row.id] = row
	}

	public func markdown(indentLevel: Int) -> String {
		fatalError("markdown not implemented")
	}
	
	public func opml(indentLevel: Int) -> String {
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

//
//  Row.swift
//  
//
//  Created by Maurice Parker on 12/24/20.
//

import Foundation

public enum Row: RowContainer, Codable, Identifiable, Equatable, Hashable {
	case blank
	case text(TextRow)
	
	public static let typeIdentifier = "io.vincode.Zavala.Row"
	
	public var parent: RowContainer? {
		get {
			associatedRow.parent
		}
		set {
			associatedRow.parent = newValue
		}
	}
	
	public var shadowTableIndex: Int? {
		get {
			associatedRow.shadowTableIndex
		}
		set {
			associatedRow.shadowTableIndex = newValue
		}
	}

	public var id: EntityID {
		get {
			associatedRow.id
		}
		set {
			associatedRow.id = newValue
		}
	}
	
	public var isExpanded: Bool {
		get {
			associatedRow.isExpanded
		}
		set {
			associatedRow.isExpanded = newValue
		}
	}
	
	public var isComplete: Bool {
		get {
			textRow!.isComplete
		}
	}
	
	public var isAncestorComplete: Bool {
		if let parentRow = parent as? Row {
			return parentRow.isComplete || parentRow.isAncestorComplete
		}
		return false
	}
	
	public var indentLevel: Int {
		var parentCount = 0
		var p = parent as? Row
		while p != nil {
			parentCount = parentCount + 1
			p = p?.parent as? Row
		}
		return parentCount
	}
	
	public var isExpandable: Bool {
		guard rowCount > 0 else { return false }
		return !isExpanded
	}

	public var isCollapsable: Bool {
		guard rowCount > 0 else { return false }
		return isExpanded
	}
	
	public var isCompletable: Bool {
		guard let textRow = textRow else { return false }
		return !textRow.isComplete
	}
	
	public var isUncompletable: Bool {
		guard let textRow = textRow else { return false }
		return textRow.isComplete
	}
	
	public var rows: [Row] {
		get {
			associatedRow.rows
		}
	}
	
	public var rowCount: Int {
		return associatedRow.rowCount
	}


	public var associatedRow: BaseRow {
		switch self {
		case .text(let row):
			return row
		default:
			fatalError()
		}
	}
	
	public var textRow: TextRow? {
		switch self {
		case .text(let row):
			return row
		default:
			fatalError()
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case type
		case textRow
	}
	
	public init(from data: Data) throws {
		let decoder = PropertyListDecoder()
		let rowData = try decoder.decode(RowData.self, from: data)
		self = rowData.row
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		
		switch type {
		case "text":
			let textRow = try container.decode(TextRow.self, forKey: .textRow)
			self = .text(textRow)
		default:
			fatalError()
		}
	}
	
	public func clone(newOutlineID: EntityID) -> Row {
		associatedRow.clone(newOutlineID: newOutlineID)
	}
	
	public func reassignAccount(_ accountID: Int) {
		associatedRow.reassignAccount(accountID)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case .text(let textRow):
			try container.encode("text", forKey: .type)
			try container.encode(textRow, forKey: .textRow)
		default:
			fatalError()
		}
	}
	
	public func firstIndexOfRow(_ row: Row) -> Int? {
		return associatedRow.firstIndexOfRow(row)
	}

	public func containsRow(_ row: Row) -> Bool {
		return associatedRow.containsRow(row)
	}

	public func insertRow(_ row: Row, at: Int) {
		associatedRow.insertRow(row, at: at)
	}

	public func removeRow(_ row: Row) {
		associatedRow.removeRow(row)
	}
	
	public func appendRow(_ row: Row) {
		associatedRow.appendRow(row)
	}
	
	public func asData() throws -> Data {
		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary
		return try encoder.encode(RowData(row: self))
	}

	public func isDecendent(_ row: Row) -> Bool {
		if let parentRow = parent as? Row, parentRow.id == row.id || parentRow.isDecendent(row) {
			return true
		}
		return false
	}
	
	/// Returns itself or the first ancestor that shares a parent with the given row
	public func ancestorSibling(_ row: Row) -> Row? {
		guard let parent = parent else { return nil }
		
		if parent.containsRow(row) || containsRow(row) {
			return self
		}
		
		if let parentRow = parent as? Row {
			return parentRow.ancestorSibling(row)
		}
		
		return nil
	}
	
	public func markdown(indentLevel: Int = 0) -> String {
		return associatedRow.markdown(indentLevel: indentLevel)
	}
	
	public func opml(indentLevel: Int = 0) -> String {
		return associatedRow.opml(indentLevel: indentLevel)
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}

	func visit(visitor: (Row) -> Void) {
		visitor(self)
	}
	
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.id == rhs.id
	}
}

extension Row: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		return associatedRow.debugDescription
	}

}

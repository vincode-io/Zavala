//
//  Row.swift
//  
//
//  Created by Maurice Parker on 12/24/20.
//

import Foundation

public enum Row: RowContainer, Codable, Identifiable, Equatable, Hashable {
	case text(TextRow)
	
	private enum CodingKeys: String, CodingKey {
		case type
		case textRow
	}
	
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

	public var id: String {
		get {
			associatedRow.id
		}
		set {
			associatedRow.id = newValue
		}
	}
	
	public var isExpanded: Bool? {
		get {
			associatedRow.isExpanded
		}
		set {
			associatedRow.isExpanded = newValue
		}
	}
	
	public var isComplete: Bool? {
		get {
			textRow?.isComplete
		}
	}
	
	public var isAncestorComplete: Bool {
		if let parentRow = parent as? Row {
			return parentRow.isComplete ?? false || parentRow.isAncestorComplete
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
		guard let rows = rows, !rows.isEmpty else { return false }
		return !(isExpanded ?? true)
	}

	public var isCollapsable: Bool {
		guard let rows = rows, !rows.isEmpty else { return false }
		return isExpanded ?? true
	}
	
	public var rows: [Row]? {
		get {
			associatedRow.rows
		}
		set {
			associatedRow.rows = newValue
		}
	}
	
	public var associatedRow: BaseRow {
		switch self {
		case .text(let row):
			return row
		}
	}
	
	public var textRow: TextRow? {
		switch self {
		case .text(let row):
			return row
		}
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
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case .text(let textRow):
			try container.encode("text", forKey: .type)
			try container.encode(textRow, forKey: .textRow)
		}
	}

	public func isDecendent(_ row: Row) -> Bool {
		if let parentRow = parent as? Row, parentRow.id == row.id || parentRow.isDecendent(row) {
			return true
		}
		return false
	}
	
	public func markdown(indentLevel: Int = 0) -> String {
		return associatedRow.markdown(indentLevel: indentLevel)
	}
	
	public func opml() -> String {
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

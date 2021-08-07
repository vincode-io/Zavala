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

	public var id: String {
		get {
			associatedRow.id
		}
		set {
			associatedRow.id = newValue
		}
	}
	
	public var entityID: EntityID {
		return associatedRow.entityID
	}
	
	public var syncID: String? {
		get {
			associatedRow.syncID
		}
		set {
			associatedRow.syncID = newValue
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
	
	public var rowOrder: [String] {
		get {
			associatedRow.rowOrder
		}
		set {
			associatedRow.rowOrder = newValue
		}
	}
	
	public var isAncestorComplete: Bool {
		associatedRow.isAncestorComplete
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
	
	public var images: [Image] {
		get {
			associatedRow.images ?? [Image]()
		}
		set {
			associatedRow.images = newValue
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
	
	var outline: Outline? {
		get {
			associatedRow.outline
		}
		set {
			associatedRow.outline = newValue
		}
	}
	
	var isPartOfSearchResult: Bool {
		get {
			associatedRow.isPartOfSearchResult
		}
		set {
			associatedRow.isPartOfSearchResult = newValue
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case type
		case textRow
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
	
	public func duplicate(newOutline: Outline) -> Row {
		switch self {
		case .text(let row):
			return .text(row.duplicate(newOutline: newOutline))
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
		default:
			fatalError()
		}
	}
	
	public func findImage(id: EntityID) -> Image? {
		return associatedRow.findImage(id: id)
	}
	
	public func saveImage(_ image: Image) {
		associatedRow.saveImage(image)
	}

	public func deleteImage(id: EntityID) {
		associatedRow.deleteImage(id: id)
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
	
	public func hasSameParent(_ row: Row) -> Bool {
		if let parentOutline = parent as? Outline, let rowOutline = row.parent as? Outline {
			return parentOutline.id == rowOutline.id
		}
		if let parentRow = parent as? Row, let rowRow = row.parent as? Row {
			return parentRow.id == rowRow.id
		}
		return false
	}
	
	public func markdown() -> String {
		let visitor = MarkdownVisitor()
		visit(visitor: visitor.visitor)
		return visitor.markdown
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

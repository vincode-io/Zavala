//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import RSCore

public extension Notification.Name {
	static let OutlineElementsDidChange = Notification.Name(rawValue: "OutlineElementsDidChange")
}

public final class Outline: RowContainer, OPMLImporter, Identifiable, Equatable, Codable {
	
	public enum Section: Int {
		case title = 0
		case tags = 1
		case rows = 2
	}

	public struct RowMove {
		public var row: Row
		public var toParent: RowContainer
		public var toChildIndex: Int
	}
	
	public var beingViewedCount = 0
	
	public var id: EntityID {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var title: String? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var created: Date? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var updated: Date? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var ownerName: String? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var ownerEmail: String? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var ownerURL: String? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var verticleScrollState: Int? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var isFiltered: Bool? {
		didSet {
			documentMetaDataDidChange()
		}
	}

	public var isNotesHidden: Bool? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var cloudKitZoneName: String? {
		didSet {
			documentMetaDataDidChange()
		}
	}

	public var cloudKitZoneOwner: String? {
		didSet {
			documentMetaDataDidChange()
		}
	}

	public var rows: [Row]? {
		get {
			if let rowOrder = rowOrder, let rowData = keyedRows {
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
				keyedRows = data
			} else {
				rowOrder = nil
				keyedRows = nil
			}
		}
	}

	public var isCloudKit: Bool {
		return AccountType(rawValue: id.accountID) == .cloudKit
	}
	
	public var shadowTable: [Row]?
	
	public var isEmpty: Bool {
		return (title == nil || title?.isEmpty ?? true) && (rowOrder == nil || rowOrder?.isEmpty ?? true)
	}
	
	public var account: Account? {
		return AccountManager.shared.findAccount(accountID: id.accountID)
	}
	
	public var tags: [Tag] {
		guard let account = account else { return [Tag]() }
		return tagIDs?.compactMap { account.findTag(tagID: $0) } ?? [Tag]()
	}
	
	public var tagCount: Int {
		return tagIDs?.count ?? 0
	}
	
	public var expansionState: String {
		get {
			var currentRow = 0
			var expandedRows = [String]()
			
			func expandedRowVisitor(_ visited: Row) {
				if visited.isCollapsable {
					expandedRows.append(String(currentRow))
				}
				currentRow = currentRow + 1
				visited.rows?.forEach { $0.visit(visitor: expandedRowVisitor) }
			}

			rows?.forEach { $0.visit(visitor: expandedRowVisitor(_:)) }
			
			return expandedRows.joined(separator: ",")
		}
		set {
			let expandedRows = newValue.split(separator: ",")
				.map({ String($0).trimmingWhitespace })
				.filter({ !$0.isEmpty })
				.compactMap({ Int($0) })
			
			var currentRow = 0
			
			func expandedRowVisitor(_ visited: Row) {
				var mutatingVisited = visited
				mutatingVisited.isExpanded = expandedRows.contains(currentRow)
				currentRow = currentRow + 1
				visited.rows?.forEach { $0.visit(visitor: expandedRowVisitor) }
			}

			rows?.forEach { $0.visit(visitor: expandedRowVisitor(_:)) }
		}
	}
	
	public var cursorCoordinates: CursorCoordinates? {
		get {
			guard let rowID = cursorRowID,
				  let row = findRow(id: rowID),
				  let isInNotes = cursorIsInNotes,
				  let position = cursorPosition else {
				return nil
			}
			return CursorCoordinates(row: row, isInNotes: isInNotes, cursorPosition: position)
		}
		set {
			cursorRowID = newValue?.row.id
			cursorIsInNotes = newValue?.isInNotes
			cursorPosition = newValue?.cursorPosition
			documentMetaDataDidChange()
		}
	}
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case title = "title"
		case created = "created"
		case updated = "updated"
		case ownerName = "ownerName"
		case ownerEmail = "ownerEmail"
		case ownerURL = "ownerURL"
		case verticleScrollState = "verticleScrollState"
		case isFiltered = "isFiltered"
		case isNotesHidden = "isNotesHidden"
		case cursorRowID = "cursorRowID"
		case cursorIsInNotes = "cursorIsInNotes"
		case cursorPosition = "cursorPosition"
		case tagIDs = "tagIDS"
		case cloudKitZoneName = "cloudKitZoneName"
		case cloudKitZoneOwner = "cloudKitZoneOwner"
	}

	var rowOrder: [EntityID]?
	var keyedRows: [EntityID: Row]?
	
	private var cursorRowID: EntityID?
	private var cursorIsInNotes: Bool?
	private var cursorPosition: Int?
	
	private var tagIDs: [String]?
	private var rowsFile: RowsFile?
	
	init(parentID: EntityID, title: String?) {
		self.id = EntityID.document(parentID.accountID, UUID().uuidString)
		self.title = title
		self.created = Date()
		self.updated = Date()
		rowsFile = RowsFile(outline: self)
	}

	public func findRow(id: EntityID) -> Row? {
		return keyedRows?[id]
	}
	
	public func insertRow(_ row: Row, at: Int) {
		if rowOrder == nil {
			rowOrder = [EntityID]()
		}
		if keyedRows == nil {
			keyedRows = [EntityID: Row]()
		}
		rowOrder?.insert(row.id, at: at)
		keyedRows?[row.id] = row
	}

	public func removeRow(_ row: Row) {
		rowOrder?.removeFirst(object: row.id)
		keyedRows?.removeValue(forKey: row.id)
	}

	public func appendRow(_ row: Row) {
		if rowOrder == nil {
			rowOrder = [EntityID]()
		}
		if keyedRows == nil {
			keyedRows = [EntityID: Row]()
		}
		rowOrder?.append(row.id)
		keyedRows?[row.id] = row
	}
	
	public func createTag(_ tag: Tag) {
		if tagIDs == nil {
			tagIDs = [String]()
		}
		tagIDs!.append(tag.id)
		self.updated = Date()

		let reload = tagIDs!.count
		let inserted = reload - 1
		let changes = OutlineElementChanges(section: .tags, inserts: Set([inserted]), reloads: Set([reload]))
		outlineElementsDidChange(changes)
	}
	
	public func deleteTag(_ tag: Tag) {
		guard let index = tagIDs?.firstIndex(where: { $0 == tag.id }) else { return }
		tagIDs?.remove(at: index)
		self.updated = Date()

		let reload = tagIDs?.count ?? 1
		let changes = OutlineElementChanges(section: .tags, deletes: Set([index]), reloads: Set([reload]))
		outlineElementsDidChange(changes)
	}
	
	public func hasTag(_ tag: Tag) -> Bool {
		guard let tagIDs = tagIDs else { return false }
		return tagIDs.contains(tag.id)
	}
	
	public func fileName(withSuffix suffix: String) -> String {
		var filename = title ?? "Outline"
		filename = filename.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespaces)
		filename = "\(filename).\(suffix)"
		return filename
	}
	
	public func childrenIndexes(forIndex: Int) -> [Int] {
		guard let row = shadowTable?[forIndex] else { return [Int]() }
		var children = [Int]()
		
		func childrenVisitor(_ visited: Row) {
			if let index = visited.shadowTableIndex {
				children.append(index)
			}
			if visited.isExpanded ?? true {
				visited.rows?.forEach { $0.visit(visitor: childrenVisitor) }
			}
		}

		if row.isExpanded ?? true {
			row.rows?.forEach { $0.visit(visitor: childrenVisitor(_:)) }
		}
		
		return children
	}
	
	public func childrenRows(forRow row: Row) -> [Row] {
		var children = [Row]()
		
		func childrenVisitor(_ visited: Row) {
			children.append(visited)
			visited.rows?.forEach { $0.visit(visitor: childrenVisitor) }
		}

		row.rows?.forEach { $0.visit(visitor: childrenVisitor(_:)) }
		return children
	}
	
	public func markdown(indentLevel: Int = 0) -> String {
		load()
		
		var md = "# \(title ?? "")\n\n"
		rows?.forEach {
			md.append($0.markdown(indentLevel: 0))
			md.append("\n")
		}
		
		suspend()
		return md
	}
	
	public func opml(indentLevel: Int = 0) -> String {
		load()

		var opml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		opml.append("<!-- OPML generated by Zavala -->\n")
		opml.append("<opml version=\"2.0\">\n")
		opml.append("<head>\n")
		opml.append("  <title>\(title?.escapingSpecialXMLCharacters ?? "")</title>\n")
		if let dateCreated = created?.rfc822String {
			opml.append("  <dateCreated>\(dateCreated)</dateCreated>\n")
		}
		if let dateModified = updated?.rfc822String {
			opml.append("  <dateModified>\(dateModified)</dateModified>\n")
		}
		if let ownerName = ownerName {
			opml.append("  <ownerName>\(ownerName.escapingSpecialXMLCharacters)</ownerName>\n")
		}
		if let ownerEmail = ownerEmail {
			opml.append("  <ownerEmail>\(ownerEmail.escapingSpecialXMLCharacters)</ownerEmail>\n")
		}
		if let ownerURL = ownerURL {
			opml.append("  <ownerID>\(ownerURL.escapingSpecialXMLCharacters)</ownerID>\n")
		}
		opml.append("  <expansionState>\(expansionState)</expansionState>\n")
		if let verticleScrollState = verticleScrollState {
			opml.append("  <vertScrollState>\(verticleScrollState)</vertScrollState>\n")
		}
		if !(tagIDs?.isEmpty ?? true) {
			opml.append("  <tags>\n")
			for tag in tags {
				opml.append("    <tag>\(tag.name.escapingSpecialXMLCharacters)</tag>\n")
			}
			opml.append("  </tags>\n")
		}
		opml.append("</head>\n")
		opml.append("<body>\n")
		rows?.forEach { opml.append($0.opml()) }
		opml.append("</body>\n")
		opml.append("</opml>\n")

		suspend()
		return opml
	}
	
	public func toggleFilter() -> OutlineElementChanges {
		isFiltered = !(isFiltered ?? false)
		documentMetaDataDidChange()
		return rebuildShadowTable()
	}
	
	public func toggleNotesHidden() -> OutlineElementChanges {
		isNotesHidden = !(isNotesHidden ?? false)
		documentMetaDataDidChange()
		
		if let reloads = shadowTable?.filter({ !(($0.associatedRow as? TextRow)?.isNoteEmpty ?? true) }).compactMap({ $0.shadowTableIndex }) {
			return OutlineElementChanges(reloads: Set(reloads))
		} else {
			return OutlineElementChanges()
		}
	}
	
	public func update(title: String) {
		self.title = title
		self.updated = Date()
		documentTitleDidChange()
	}
	
	public func isCreateNotesUnavailable(rows: [Row]) -> Bool {
		return rows.isEmpty
	}
	
	func createNotes(rows: [Row], textRowStrings: TextRowStrings?) -> ([Row], Int?) {
		if rows.count == 1, let textRow = rows.first?.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}

		var impacted = [Row]()
		for row in rows {
			if let textRow = row.textRow, textRow.note == nil {
				textRow.note = NSAttributedString()
				impacted.append(row)
			}
		}
		
		outlineBodyDidChange()
		
		let reloads = impacted.compactMap { $0.shadowTableIndex }
		let changes = OutlineElementChanges(reloads: Set(reloads))
		outlineElementsDidChange(changes)
		return (impacted, reloads.sorted().first)
	}
	
	public func isDeleteNotesUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if let textRow = row.textRow, !textRow.isNoteEmpty {
				return false
			}
		}
		return true
	}
	
	@discardableResult
	func deleteNotes(rows: [Row], textRowStrings: TextRowStrings?) -> ([Row: NSAttributedString], Int?) {
		if rows.count == 1, let textRow = rows.first?.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}

		var impacted = [Row: NSAttributedString]()
		for row in rows {
			if let textRow = row.textRow, textRow.note != nil {
				impacted[row] = textRow.note
				textRow.note = nil
			}
		}

		outlineBodyDidChange()
		
		let reloads = impacted.keys.compactMap { $0.shadowTableIndex }
		let changes = OutlineElementChanges(reloads: Set(reloads))
		outlineElementsDidChange(changes)
		return (impacted, reloads.sorted().first)
	}
	
	func restoreNotes(_ notes: [Row: NSAttributedString]) {
		for (row, note) in notes {
			row.textRow?.note = note
		}

		outlineBodyDidChange()
		
		let reloads = notes.keys.compactMap { $0.shadowTableIndex }
		let changes = OutlineElementChanges(reloads: Set(reloads))
		outlineElementsDidChange(changes)
	}
	
	@discardableResult
	func deleteRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) -> Int? {
		if rows.count == 1, let textRow = rows.first?.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}

		var deletes = [Int]()

		for row in rows {
			row.parent?.removeRow(row)
			
			guard let rowShadowTableIndex = row.shadowTableIndex else { return nil }
			deletes.append(rowShadowTableIndex)
			
			func deleteVisitor(_ visited: Row) {
				if let index = visited.shadowTableIndex {
					deletes.append(index)
				}
				if visited.isExpanded ?? true {
					visited.rows?.forEach { $0.visit(visitor: deleteVisitor) }
				}
			}

			if row.isExpanded ?? true {
				row.rows?.forEach { $0.visit(visitor: deleteVisitor(_:)) }
			}
		}

		outlineBodyDidChange()
		
		var deletedRows = [Row]()
		
		deletes.sort(by: { $0 > $1 })
		for index in deletes {
			if let deletedRow = shadowTable?.remove(at: index) {
				deletedRows.append(deletedRow)
			}
		}
		
		guard let lowestShadowTableIndex = deletes.last else { return nil }
		resetShadowTableIndexes(startingAt: lowestShadowTableIndex)
		
		let reloads = rows.compactMap { ($0.parent as? Row)?.shadowTableIndex }
		
		let changes = OutlineElementChanges(deletes: Set(deletes), reloads: Set(reloads))
		outlineElementsDidChange(changes)
		
		if let firstDelete = deletes.first, firstDelete > 0 {
			return firstDelete - 1
		} else {
			return nil
		}
	}
	
	func joinRows(topRow: Row, bottomRow: Row) {
		guard let topTextRow = topRow.textRow,
			  let topTopic = topTextRow.topic,
			  let topShadowTableIndex = topRow.shadowTableIndex,
			  let bottomTopic = bottomRow.textRow?.topic else { return }
		
		let mutableText = NSMutableAttributedString(attributedString: topTopic)
		mutableText.append(bottomTopic)
		topTextRow.topic = mutableText
		
		deleteRows([bottomRow])
		let changes = OutlineElementChanges(reloads: Set([topShadowTableIndex]))
		outlineElementsDidChange(changes)
	}
	
	func createRow(_ row: Row, beforeRow: Row, textRowStrings: TextRowStrings? = nil) -> Int? {
		if let beforeTextRow = beforeRow.textRow, let texts = textRowStrings {
			beforeTextRow.textRowStrings = texts
		}

		guard let parent = beforeRow.parent,
			  let index = parent.rows?.firstIndex(of: beforeRow),
			  let shadowTableIndex = beforeRow.shadowTableIndex else {
			return nil
		}
		
		parent.insertRow(row, at: index)
		var mutatingRow = row
		mutatingRow.parent = parent
		
		outlineBodyDidChange()

		shadowTable?.insert(row, at: shadowTableIndex)
		resetShadowTableIndexes(startingAt: shadowTableIndex)
		let changes = OutlineElementChanges(inserts: [shadowTableIndex])
		outlineElementsDidChange(changes)
		
		return shadowTableIndex
	}
	
	@discardableResult
	func createRows(_ rows: [Row], afterRow: Row? = nil, textRowStrings: TextRowStrings? = nil, prefersEnd: Bool = false) -> Int? {
		if let afterTextRow = afterRow?.textRow, let texts = textRowStrings {
			afterTextRow.textRowStrings = texts
		}

		// TODO: Go through here and change to use insertRow on this object
		for row in rows.sortedByReverseDisplayOrder() {
			if afterRow == nil {
				var rows = self.rows ?? [Row]()
				if prefersEnd {
					rows.append(row)
				} else {
					rows.insert(row, at: 0)
				}
				var mutatingRow = row
				mutatingRow.parent = self
				self.rows = rows
			} else if let parent = row.parent, parent as? Row == afterRow {
				parent.insertRow(row, at: 0)
			} else if var parent = row.parent {
				var rows = parent.rows ?? [Row]()
				let insertIndex = rows.firstIndex(where: { $0 == afterRow}) ?? rows.count - 1
				rows.insert(row, at: insertIndex + 1)
				parent.rows = rows
			} else if afterRow?.isExpanded ?? true && !(afterRow?.rows?.isEmpty ?? true) {
				afterRow?.insertRow(row, at: 0)
				var mutatingRow = row
				mutatingRow.parent = afterRow
			} else if var parent = afterRow?.parent {
				var rows = parent.rows ?? [Row]()
				let insertIndex = rows.firstIndex(where: { $0 == afterRow}) ?? -1
				rows.insert(row, at: insertIndex + 1)
				var mutatingRow = row
				mutatingRow.parent = afterRow?.parent
				parent.rows = rows
			} else {
				var rows = self.rows ?? [Row]()
				let insertIndex = rows.firstIndex(where: { $0 == afterRow}) ?? -1
				rows.insert(row, at: insertIndex + 1)
				var mutatingRow = row
				mutatingRow.parent = self
				self.rows = rows
			}
		}
		
		func parentVisitor(_ visited: Row) {
			visited.rows?.forEach {
				var mutatingRow = $0
				mutatingRow.parent = visited
				$0.visit(visitor: parentVisitor)
			}
		}

		for row in rows {
			row.rows?.forEach {
				var mutatingRow = $0
				mutatingRow.parent = row
				$0.visit(visitor: parentVisitor(_:))
			}
		}

		outlineBodyDidChange()

		var insertedRows = [Row]()
		
		func insertVisitor(_ visited: Row) {
			insertedRows.append(visited)
			if visited.isExpanded ?? true {
				visited.rows?.forEach { $0.visit(visitor: insertVisitor) }
			}
		}

		for row in rows {
			insertedRows.append(row)
			if row.isExpanded ?? true {
				row.rows?.forEach { $0.visit(visitor: insertVisitor(_:)) }
			}
		}
		
		let rowShadowTableIndex: Int
		if let afterRowShadowTableIndex = afterRow?.shadowTableIndex {
			rowShadowTableIndex = afterRowShadowTableIndex + 1
		} else {
			if prefersEnd {
				rowShadowTableIndex = shadowTable?.count ?? 0
			} else {
				rowShadowTableIndex = 0
			}
		}
		
		var reloads = [Int]()
		if let reload = afterRow?.shadowTableIndex {
			reloads.append(reload)
		}

		var inserts = [Int]()
		for i in 0..<insertedRows.count {
			let shadowTableIndex = rowShadowTableIndex + i
			inserts.append(shadowTableIndex)
			shadowTable?.insert(insertedRows[i], at: shadowTableIndex)
		}
		
		resetShadowTableIndexes(startingAt: afterRow?.shadowTableIndex ?? 0)
		let changes = OutlineElementChanges(inserts: Set(inserts), reloads: Set(reloads))
		outlineElementsDidChange(changes)
		
		return inserts.count > 0 ? inserts[0] : nil
	}
	
	func splitRow(newRow: Row, row: Row, topic: NSAttributedString, cursorPosition: Int) -> Int? {
		guard let newTextRow = newRow.textRow, let textRow = row.textRow else { return nil }
		
		let newTopicRange = NSRange(location: cursorPosition, length: topic.length - cursorPosition)
		let newTopicText = topic.attributedSubstring(from: newTopicRange)
		newTextRow.topic = newTopicText
		
		let topicRange = NSRange(location: 0, length: cursorPosition)
		let topicText = topic.attributedSubstring(from: topicRange)
		textRow.topic = topicText

		let newCursorIndex = createRows([newRow], afterRow: row)

		if let rowShadowTableIndex = textRow.shadowTableIndex {
			let reloadChanges = OutlineElementChanges(reloads: Set([rowShadowTableIndex]))
			outlineElementsDidChange(reloadChanges)
		}

		return newCursorIndex
	}

	func updateRow(_ row: Row, textRowStrings: TextRowStrings?, applyChanges: Bool) {
		if let textRow = row.textRow, let textRowStrings = textRowStrings {
			textRow.textRowStrings = textRowStrings
		}
		
		outlineBodyDidChange()
		
		if applyChanges {
			guard let shadowTableIndex = row.shadowTableIndex else { return }
			let changes = OutlineElementChanges(reloads: [shadowTableIndex])
			outlineElementsDidChange(changes)
		}
	}
	
	@discardableResult
	public func expand(rows: [Row]) -> [Row] {
		if rows.count == 1, let row = rows.first {
			expand(row: row)
			return [row]
		}
		return expandCollapse(rows: rows, isExpanded: true)
	}
	
	@discardableResult
	func collapse(rows: [Row]) -> [Row] {
		if rows.count == 1, let row = rows.first {
			collapse(row: row)
			return [row]
		}
		return expandCollapse(rows: rows, isExpanded: false)
	}
	
	public func isExpandAllUnavailable(containers: [RowContainer]) -> Bool {
		for container in containers {
			if !isExpandAllUnavailable(container: container) {
				return false
			}
		}
		return true
	}
	
	func expandAll(containers: [RowContainer]) -> [Row] {
		var impacted = [Row]()
		
		for container in containers {
			if let row = container as? Row, row.isExpandable {
				var mutatingRow = row
				mutatingRow.isExpanded = true
				impacted.append(row)
			}
			
			func expandVisitor(_ visited: Row) {
				if visited.isExpandable {
					var mutatingVisited = visited
					mutatingVisited.isExpanded = true
					impacted.append(visited)
				}
				visited.rows?.forEach { $0.visit(visitor: expandVisitor) }
			}

			container.rows?.forEach { $0.visit(visitor: expandVisitor(_:)) }
		}

		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		
		let reloads = Set(impacted.compactMap { $0.shadowTableIndex })
		changes.append(OutlineElementChanges(reloads: reloads))
		outlineElementsDidChange(changes)
		return impacted
	}

	public func isCollapseAllUnavailable(containers: [RowContainer]) -> Bool {
		for container in containers {
			if !isCollapseAllUnavailable(container: container) {
				return false
			}
		}
		return true
	}
	
	func collapseAll(containers: [RowContainer]) -> [Row] {
		var impacted = [Row]()
		var reloads = [Row]()

		for container in containers {
			if let row = container as? Row, row.isCollapsable {
				var mutatingRow = row
				mutatingRow.isExpanded = false
				impacted.append(row)
			}
			
			func collapseVisitor(_ visited: Row) {
				if visited.isCollapsable {
					var mutatingVisited = visited
					mutatingVisited.isExpanded = false
					impacted.append(visited)
				}
				visited.rows?.forEach { $0.visit(visitor: collapseVisitor) }
			}

			if let row = container as? Row {
				reloads.append(row)
			}
			
			container.rows?.forEach {
				reloads.append($0)
				$0.visit(visitor: collapseVisitor(_:))
			}
		}
		
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
	
		let reloadIndexes = Set(reloads.compactMap { $0.shadowTableIndex })
		changes.append(OutlineElementChanges(reloads: reloadIndexes))
		
		outlineElementsDidChange(changes)
		return impacted
	}

	public func isCompleteUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if row.isCompletable {
				return false
			}
		}
		return true
	}
	
	@discardableResult
	func complete(rows: [Row], textRowStrings: TextRowStrings?) -> ([Row], Int?) {
		return completeUncomplete(rows: rows, isComplete: true, textRowStrings: textRowStrings)
	}
	
	public func isUncompleteUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if row.isUncompletable {
				return false
			}
		}
		return true
	}
	
	@discardableResult
	func uncomplete(rows: [Row], textRowStrings: TextRowStrings?) -> [Row] {
		let (impacted, _) = completeUncomplete(rows: rows, isComplete: false, textRowStrings: textRowStrings)
		return impacted
	}
	
	public func isIndentRowsUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if let rowIndex = row.parent?.rows?.firstIndex(of: row), rowIndex > 0 {
				return false
			}
		}
		return true
	}
	
	func indentRows(_ rows: [Row], textRowStrings: TextRowStrings?) -> [Row] {
		if rows.count == 1, let textRow = rows.first?.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}
		
		let sortedRows = rows.sortedByDisplayOrder()

		var impacted = [Row]()
		var reloads = Set<Int>()

		for row in sortedRows {
			guard let container = row.parent,
				  let rowIndex = container.rows?.firstIndex(of: row),
				  rowIndex > 0,
				  var newParentRow = container.rows?[rowIndex - 1],
				  let rowShadowTableIndex = row.shadowTableIndex,
				  let newParentRowShadowTableIndex = newParentRow.shadowTableIndex else { continue }

			impacted.append(row)
			expand(row: newParentRow)
			
			let siblingRows = newParentRow.rows ?? [Row]()
			var mutatingRow = row
			mutatingRow.parent = newParentRow
			newParentRow.appendRow(row)
			newParentRow.rows = siblingRows
			container.removeRow(row)

			newParentRow.isExpanded = true

			reloads.insert(newParentRowShadowTableIndex)
			reloads.insert(rowShadowTableIndex)
		}
		
		outlineBodyDidChange()
		
		func reloadVisitor(_ visited: Row) {
			if let index = visited.shadowTableIndex {
				reloads.insert(index)
			}
			if visited.isExpanded ?? true {
				visited.rows?.forEach { $0.visit(visitor: reloadVisitor) }
			}
		}

		for row in impacted {
			if row.isExpanded ?? true {
				row.rows?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
			}
		}

		let changes = OutlineElementChanges(reloads: reloads)
		outlineElementsDidChange(changes)
		return impacted
	}
	
	public func isOutdentRowsUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if row.indentLevel != 0 {
				return false
			}
		}
		return true
	}
		
	@discardableResult
	func outdentRows(_ rows: [Row], textRowStrings: TextRowStrings?) -> [Row] {
		if rows.count == 1, let textRow = rows.first?.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}

		var impacted = [Row]()

		for row in rows.sortedWithDecendentsFiltered().reversed() {
			guard let oldParent = row.parent as? Row,
				  let oldParentRows = oldParent.rows,
				  let oldRowIndex = oldParentRows.firstIndex(of: row),
				  let newParent = oldParent.parent,
				  let oldParentIndex = newParent.rows?.firstIndex(of: oldParent) else { continue }
			
			impacted.append(row)
			
			var siblingsToMove = [Row]()
			for i in (oldRowIndex + 1)..<oldParentRows.count {
				siblingsToMove.append(oldParentRows[i])
			}

			oldParent.removeRow(row)
			newParent.insertRow(row, at: oldParentIndex + 1)
			
			var mutatingRow = row
			mutatingRow.parent = oldParent.parent
		}

		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		let reloads = reloadsForParentAndChildren(rows: impacted)
		changes.append(OutlineElementChanges(reloads: reloads))
		outlineElementsDidChange(changes)
		
		return impacted
	}
	
	func moveRows(_ rowMoves: [RowMove], textRowStrings: TextRowStrings?) {
		if rowMoves.count == 1, let textRow = rowMoves.first?.row.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}

		var oldParentReloads = Set<Int>()

		let sortedRowMoves = rowMoves.sorted { (lhs, rhs) -> Bool in
			if lhs.toParent is Outline && rhs.toParent is Outline {
				return lhs.toChildIndex < rhs.toChildIndex
			}
			
			if lhs.toParent is Row && rhs.toParent is Outline {
				return true
			}
			
			if lhs.toParent is Outline && rhs.toParent is Row {
				return false
			}
			
			guard let lhsToParentRow = lhs.toParent as? Row, let rhsToParentRow = rhs.toParent as? Row else { fatalError() }
			
			if lhsToParentRow == rhsToParentRow {
				return lhs.toChildIndex < rhs.toChildIndex
			}
			
			return lhsToParentRow.shadowTableIndex ?? -1 < rhsToParentRow.shadowTableIndex ?? -1
		}
		
		// Move the rows in the tree
		for rowMove in sortedRowMoves {
			var mutatingToParent = rowMove.toParent
			
			rowMove.row.parent?.removeRow(rowMove.row)
			if let oldParentShadowTableIndex = (rowMove.row.parent as? Row)?.shadowTableIndex {
				oldParentReloads.insert(oldParentShadowTableIndex)
			}
			
			if mutatingToParent.rows == nil {
				mutatingToParent.rows = [rowMove.row]
			} else {
				if rowMove.toChildIndex >= mutatingToParent.rows!.count {
					mutatingToParent.appendRow(rowMove.row)
				} else {
					mutatingToParent.insertRow(rowMove.row, at: rowMove.toChildIndex)
				}
			}
		}

		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		var reloads = reloadsForParentAndChildren(rows: rowMoves.map { $0.row })
		reloads.formUnion(oldParentReloads)
		changes.append(OutlineElementChanges(reloads: reloads))
		outlineElementsDidChange(changes)
	}
	
	public func load() {
		guard rowsFile == nil else { return }
		rowsFile = RowsFile(outline: self)
		rowsFile!.load()
		rebuildTransientData()
	}
	
	public func save() {
		rowsFile?.save()
	}
	
	public func forceSave() {
		if rowsFile == nil {
			rowsFile = RowsFile(outline: self)
		}
		rowsFile?.markAsDirty()
		rowsFile?.save()
	}
	
	public func delete() {
		if rowsFile == nil {
			rowsFile = RowsFile(outline: self)
		}
		rowsFile?.delete()
		rowsFile = nil
		outlineDidDelete()
	}
	
	public func suspend() {
		rowsFile?.save()
		
		guard beingViewedCount < 1 else { return }
		
		rowsFile = nil
		shadowTable = nil
		rowOrder = nil
		keyedRows = nil
	}
	
	public static func == (lhs: Outline, rhs: Outline) -> Bool {
		return lhs.id == rhs.id
	}
	
}

// MARK: CustomDebugStringConvertible

extension Outline: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		var output = ""
		for row in rows ?? [Row]() {
			output.append(dumpRow(level: 0, row: row))
		}
		return output
	}
	
	private func dumpRow(level: Int, row: Row) -> String {
		var output = ""
		for _ in 0..<level {
			output.append(" -- ")
		}
		output.append(row.debugDescription)
		output.append("\n")
		
		for child in row.rows ?? [Row]() {
			output.append(dumpRow(level: level + 1, row: child))
		}
		
		return output
	}
	
}

// MARK: Helpers

extension Outline {
	
	private func documentTitleDidChange() {
		NotificationCenter.default.post(name: .DocumentTitleDidChange, object: Document.outline(self), userInfo: nil)
	}

	private func documentMetaDataDidChange() {
		NotificationCenter.default.post(name: .DocumentMetaDataDidChange, object: Document.outline(self), userInfo: nil)
	}

	private func outlineBodyDidChange() {
		self.updated = Date()
		documentMetaDataDidChange()
		rowsFile?.markAsDirty()
	}
	
	private func outlineElementsDidChange(_ changes: OutlineElementChanges) {
		var userInfo = [AnyHashable: Any]()
		userInfo[OutlineElementChanges.userInfoKey] = changes
		NotificationCenter.default.post(name: .OutlineElementsDidChange, object: self, userInfo: userInfo)
	}

	private func outlineDidDelete() {
		NotificationCenter.default.post(name: .DocumentDidDelete, object: Document.outline(self), userInfo: nil)
	}
	
	private func completeUncomplete(rows: [Row], isComplete: Bool, textRowStrings: TextRowStrings?) -> ([Row], Int?) {
		if rows.count == 1, let textRow = rows.first?.textRow, let textRowStrings = textRowStrings {
			textRow.textRowStrings = textRowStrings
		}
		
		var impacted = [Row]()
		
		for row in rows {
			if isComplete != row.isComplete ?? false {
				row.textRow?.isComplete = isComplete
				impacted.append(row)
			}
		}
		
		outlineBodyDidChange()
		
		if isFiltered ?? false {
			let changes = rebuildShadowTable()
			outlineElementsDidChange(changes)
			if let firstComplete = changes.deletes?.sorted().first, firstComplete > 0 {
				return (impacted, firstComplete - 1)
			} else {
				return (impacted, 0)
			}
		}
		
		var reloads = Set<Int>()
		
		for row in impacted {
			if let shadowTableIndex = row.shadowTableIndex {
				reloads.insert(shadowTableIndex)
			
				func reloadVisitor(_ visited: Row) {
					if let index = visited.shadowTableIndex {
						reloads.insert(index)
					}
					if visited.isExpanded ?? true {
						visited.rows?.forEach { $0.visit(visitor: reloadVisitor) }
					}
				}

				if row.isExpanded ?? true {
					row.rows?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
				}
			}
		}
		
		let changes = OutlineElementChanges(reloads: reloads)
		outlineElementsDidChange(changes)
		return (impacted, nil)
	}

	private func isExpandAllUnavailable(container: RowContainer) -> Bool {
		if let row = container as? Row, row.isExpandable {
			return false
		}

		var unavailable = true
		
		func expandedRowVisitor(_ visited: Row) {
			for row in visited.rows ?? [Row]() {
				unavailable = !row.isExpandable
				if !unavailable {
					break
				}
				row.visit(visitor: expandedRowVisitor)
				if !unavailable {
					break
				}
			}
		}

		for row in container.rows ?? [Row]() {
			unavailable = !row.isExpandable
			if !unavailable {
				break
			}
			row.visit(visitor: expandedRowVisitor)
			if !unavailable {
				break
			}
		}
		
		return unavailable
	}
	
	private func expandCollapse(rows: [Row], isExpanded: Bool) -> [Row] {
		var impacted = [Row]()
		
		for row in rows {
			if isExpanded != row.isExpanded ?? true {
				var mutatingRow = row
				mutatingRow.isExpanded = isExpanded
				impacted.append(mutatingRow)
			}
		}
		
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		
		let reloads = Set(rows.compactMap { $0.shadowTableIndex })
		changes.append(OutlineElementChanges(reloads: reloads))
		
		outlineElementsDidChange(changes)
		return impacted
	}
	
	private func expand(row: Row) {
		guard !(row.isExpanded ?? true), let rowShadowTableIndex = row.shadowTableIndex else { return }
		
		var mutatingRow = row
		mutatingRow.isExpanded = true

		outlineBodyDidChange()
		
		var shadowTableInserts = [Row]()

		func visitor(_ visited: Row) {
			let shouldFilter = isFiltered ?? false && visited.isComplete ?? false
			
			if !shouldFilter {
				shadowTableInserts.append(visited)

				if visited.isExpanded ?? true {
					visited.rows?.forEach {
						$0.visit(visitor: visitor)
					}
				}
			}
		}

		row.rows?.forEach { row in
			row.visit(visitor: visitor(_:))
		}
		
		var inserts = Set<Int>()
		for i in 0..<shadowTableInserts.count {
			let newIndex = i + rowShadowTableIndex + 1
			shadowTable?.insert(shadowTableInserts[i], at: newIndex)
			inserts.insert(newIndex)
		}
		
		resetShadowTableIndexes(startingAt: rowShadowTableIndex)
		let changes = OutlineElementChanges(inserts: inserts, reloads: [rowShadowTableIndex])
		outlineElementsDidChange(changes)
	}

	private func isCollapseAllUnavailable(container: RowContainer) -> Bool {
		if let row = container as? Row, row.isCollapsable {
			return false
		}
		
		var unavailable = true
		
		func collapsedRowVisitor(_ visited: Row) {
			for row in visited.rows ?? [Row]() {
				unavailable = !row.isCollapsable
				if !unavailable {
					break
				}
				row.visit(visitor: collapsedRowVisitor)
				if !unavailable {
					break
				}
			}
		}

		for row in container.rows ?? [Row]() {
			unavailable = !row.isCollapsable
			if !unavailable {
				break
			}
			row.visit(visitor: collapsedRowVisitor)
			if !unavailable {
				break
			}
		}
		
		return unavailable
	}
	
	private func collapse(row: Row)  {
		guard row.isExpanded ?? true else { return  }

		var mutatingRow = row
		mutatingRow.isExpanded = false
			
		outlineBodyDidChange()
		
		var reloads = Set<Int>()

		func visitor(_ visited: Row) {
			if let shadowTableIndex = visited.shadowTableIndex {
				reloads.insert(shadowTableIndex)
			}

			if visited.isExpanded ?? true {
				visited.rows?.forEach {
					$0.visit(visitor: visitor)
				}
			}
		}
		
		row.rows?.forEach { row in
			row.visit(visitor: visitor(_:))
		}
		
		shadowTable?.remove(atOffsets: IndexSet(reloads))
		
		guard let rowShadowTableIndex = row.shadowTableIndex else { return }
		resetShadowTableIndexes(startingAt: rowShadowTableIndex)
		let changes = OutlineElementChanges(deletes: reloads, reloads: Set([rowShadowTableIndex]))
		outlineElementsDidChange(changes)
	}
	
	private func rebuildShadowTable() -> OutlineElementChanges {
		guard let oldShadowTable = shadowTable else { return OutlineElementChanges() }
		rebuildTransientData()
		
		var moves = Set<OutlineElementChanges.Move>()
		var inserts = Set<Int>()
		var deletes = Set<Int>()
		
		let diff = shadowTable!.difference(from: oldShadowTable).inferringMoves()
		for change in diff {
			switch change {
			case .insert(let offset, _, let associated):
				if let associated = associated {
					moves.insert(OutlineElementChanges.Move(associated, offset))
				} else {
					inserts.insert(offset)
				}
			case .remove(let offset, _, let associated):
				if let associated = associated {
					moves.insert(OutlineElementChanges.Move(offset, associated))
				} else {
					deletes.insert(offset)
				}
			}
		}
		
		return OutlineElementChanges(deletes: deletes, inserts: inserts, moves: moves)
	}
	
	private func rebuildTransientData() {
		let transient = TransientDataVisitor(isFiltered: isFiltered ?? false)
		rows?.forEach { row in
			var mutatingRow = row
			mutatingRow.parent = self
			row.visit(visitor: transient.visitor(_:))
		}
		self.shadowTable = transient.shadowTable
	}
	
	private func resetShadowTableIndexes(startingAt: Int = 0) {
		guard var shadowTable = shadowTable else { return }
		for i in startingAt..<shadowTable.count {
			shadowTable[i].shadowTableIndex = i
		}
	}
	
	private func reloadsForParentAndChildren(rows: [Row]) -> Set<Int> {
		var reloads = Set<Int>()
		
		for row in rows {
			guard let shadowTableIndex = row.shadowTableIndex else { continue }
			
			reloads.insert(shadowTableIndex)
			if shadowTableIndex > 0 {
				reloads.insert(shadowTableIndex - 1)
			}
			
			func reloadVisitor(_ visited: Row) {
				if let index = visited.shadowTableIndex {
					reloads.insert(index)
				}
				if visited.isExpanded ?? true {
					visited.rows?.forEach { $0.visit(visitor: reloadVisitor) }
				}
			}

			if row.isExpanded ?? true {
				row.rows?.forEach { $0.visit(visitor: reloadVisitor(_:)) }
			}
		}

		return reloads
	}
	
}

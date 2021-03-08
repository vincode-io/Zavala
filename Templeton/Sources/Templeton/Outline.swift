//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import RSCore
import CloudKit

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
	
	public enum SearchState {
		case beginSearch
		case searching
		case notSearching
	}
	
	public private(set) var isSearching = SearchState.notSearching
	
	public var adjustedRowsSection: Section {
		return isSearching == .notSearching ? Section.rows : Section.title
	}
	
	public var beingViewedCount = 0
	
	public var id: EntityID {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public internal(set) var title: String? {
		didSet {
			if title != oldValue {
				updated = Date()
				documentTitleDidChange()
			}
		}
	}
	
	public internal(set) var ownerName: String? {
		didSet {
			if ownerName != oldValue {
				updated = Date()
			}
		}
	}
	
	public internal(set) var ownerEmail: String? {
		didSet {
			if ownerEmail != oldValue {
				updated = Date()
			}
		}
	}
	
	public internal(set) var ownerURL: String? {
		didSet {
			if ownerURL != oldValue {
				updated = Date()
			}
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

	public var cloudKitShareRecordName: String? {
		didSet {
			if cloudKitShareRecordName != oldValue {
				documentSharingDidChange()
				documentMetaDataDidChange()
			}
		}
	}

	public var rows: [Row] {
		get {
			if let rowOrder = rowOrder, let rowData = keyedRows {
				return rowOrder.compactMap { rowData[$0] }
			} else {
				return [Row]()
			}
		}
	}
	
	public var rowCount: Int {
		return rowOrder?.count ?? 0
	}

	public var isCloudKit: Bool {
		return AccountType(rawValue: id.accountID) == .cloudKit
	}
	
	public private(set) var shadowTable: [Row]?
	
	public var isEmpty: Bool {
		return (title == nil || title?.isEmpty ?? true) && (rowOrder == nil || rowOrder?.isEmpty ?? true)
	}
	
	public var isShared: Bool {
		return cloudKitShareRecordName != nil
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
				visited.rows.forEach { $0.visit(visitor: expandedRowVisitor) }
			}

			rows.forEach { $0.visit(visitor: expandedRowVisitor(_:)) }
			
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
				visited.rows.forEach { $0.visit(visitor: expandedRowVisitor) }
			}

			rows.forEach { $0.visit(visitor: expandedRowVisitor(_:)) }
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
	
	public var isAnyRowCompleted: Bool {
		var anyCompleted = false
		
		if let keyedRows = keyedRows {
			for row in keyedRows.values {
				if row.isComplete {
					anyCompleted = true
					break
				}
			}
		}
		
		return anyCompleted
	}
	
	public var allCompletedRows: [Row] {
		var completedRows = [Row]()
		
		if let keyedRows = keyedRows {
			for row in keyedRows.values {
				if row.isComplete {
					completedRows.append(row)
				}
			}
		}

		return completedRows
	}
	
	public private(set) var currentSearchResult = 0
	public var searchResultCount: Int {
		return searchResultCoordinates.count
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
		case cloudKitShareRecordName = "cloudKitShareRecordName"
	}

	var zoneID: CKRecordZone.ID? {
		get {
			guard let zoneName = cloudKitZoneName, let zoneOwner = cloudKitZoneOwner else { return nil }
			return CKRecordZone.ID(zoneName: zoneName, ownerName: zoneOwner)
		}
		set {
			cloudKitZoneName = newValue?.zoneName
			cloudKitZoneOwner = newValue?.ownerName
		}
	}
	
	var shareRecordID: CKRecord.ID? {
		get {
			guard let recordName = cloudKitShareRecordName, let zoneID = zoneID else { return nil }
			return CKRecord.ID(recordName: recordName, zoneID: zoneID)
		}
		set {
			cloudKitShareRecordName = newValue?.recordName
			zoneID = newValue?.zoneID
		}
	}
	
	var rowOrder: [EntityID]? {
		didSet {
			if rowOrder != oldValue {
				updated = Date()
			}
		}
	}
	
	var keyedRows: [EntityID: Row]?
	
	private var cursorRowID: EntityID?
	private var cursorIsInNotes: Bool?
	private var cursorPosition: Int?
	
	private var tagIDs: [String]? {
		didSet {
			if tagIDs != oldValue {
				updated = Date()
			}
		}
	}
	
	private var rowsFile: RowsFile?
	
	private var batchCloudKitRequests = 0
	private var cloudKitRequestsIDs = Set<EntityID>()
	
	private var searchResultCoordinates = [SearchResultCoordinates]()
	
	init(id: EntityID) {
		self.id = id
		self.created = Date()
		self.updated = Date()
		rowsFile = RowsFile(outline: self)
	}

	init(parentID: EntityID, title: String?) {
		self.id = .document(parentID.accountID, UUID().uuidString)
		self.title = title
		self.created = Date()
		self.updated = Date()
		rowsFile = RowsFile(outline: self)
	}

	public func reassignAccount(_ accountID: Int) {
		self.id = .document(accountID, id.documentUUID)

		guard let keyedRows = keyedRows else { return }

		var newOrder = [EntityID]()
		for row in rowOrder ?? [EntityID]() {
			newOrder.append(.row(accountID, row.documentUUID, row.rowUUID))
		}
		rowOrder = newOrder

		var newKeyedRows = [EntityID: Row]()
		for key in keyedRows.keys {
			if let row = keyedRows[key] {
				row.reassignAccount(accountID)
				newKeyedRows[row.id] = row
			}
		}
		
		self.keyedRows = newKeyedRows
	}
	
	public func prepareForViewing() {
		rebuildTransientData()
	}
	
	public func findRow(id: EntityID) -> Row? {
		return keyedRows?[id]
	}
	
	public func firstIndexOfRow(_ row: Row) -> Int? {
		return rowOrder?.firstIndex(of: row.id)
	}

	public func containsRow(_ row: Row) -> Bool {
		return rowOrder?.contains(row.id) ?? false
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

		requestCloudKitUpdates(for: [id, row.id])
	}

	public func removeRow(_ row: Row) {
		rowOrder?.removeFirst(object: row.id)
		keyedRows?.removeValue(forKey: row.id)
		requestCloudKitUpdates(for: [id, row.id])
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

		requestCloudKitUpdates(for: [id, row.id])
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
		
		requestCloudKitUpdate(for: id)
	}
	
	public func deleteTag(_ tag: Tag) {
		guard let index = tagIDs?.firstIndex(where: { $0 == tag.id }) else { return }
		tagIDs?.remove(at: index)
		self.updated = Date()

		let reload = tagIDs?.count ?? 1
		let changes = OutlineElementChanges(section: .tags, deletes: Set([index]), reloads: Set([reload]))
		outlineElementsDidChange(changes)
		
		requestCloudKitUpdate(for: id)
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
			if visited.isExpanded {
				visited.rows.forEach { $0.visit(visitor: childrenVisitor) }
			}
		}

		if row.isExpanded {
			row.rows.forEach { $0.visit(visitor: childrenVisitor(_:)) }
		}
		
		return children
	}
	
	public func childrenRows(forRow row: Row) -> [Row] {
		var children = [Row]()
		
		func childrenVisitor(_ visited: Row) {
			children.append(visited)
			visited.rows.forEach { $0.visit(visitor: childrenVisitor) }
		}

		row.rows.forEach { $0.visit(visitor: childrenVisitor(_:)) }
		return children
	}
	
	public func markdown(indentLevel: Int = 0) -> String {
		load()
		
		var md = "# \(title ?? "")\n\n"
		rows.forEach {
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
		rows.forEach { opml.append($0.opml()) }
		opml.append("</body>\n")
		opml.append("</opml>\n")

		suspend()
		return opml
	}
	
	public func update(title: String) {
		self.title = title
		requestCloudKitUpdate(for: id)
	}
	
	public func update(ownerName: String?, ownerEmail: String?, ownerURL: String?) {
		self.ownerName = ownerName
		self.ownerEmail = ownerEmail
		self.ownerURL = ownerURL
		requestCloudKitUpdate(for: id)
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
			return OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
		} else {
			return OutlineElementChanges(section: adjustedRowsSection)
		}
	}
	
	public func isCreateNotesUnavailable(rows: [Row]) -> Bool {
		return rows.isEmpty
	}
	
	public func beginSearching() {
		isSearching = .beginSearch
		var changes = rebuildShadowTable()

		if let inserts = changes.inserts {
			let reloads = inserts.compactMap { (shadowTable?[$0].parent as? Row)?.shadowTableIndex }
			changes.append(OutlineElementChanges(section: .rows, reloads: Set(reloads)))
		}
		
		outlineElementsDidChange(changes)
	}
	
	public func search(for searchText: String) {
		clearSearchResults()
		
		if searchText.isEmpty {
			isSearching = .beginSearch
		} else {
			isSearching = .searching
			let searchVisitor = SearchResultVisitor(searchText: searchText, isFiltered: isFiltered ?? false, isNotesHidden: isNotesHidden ?? false)
			rows.forEach { $0.visit(visitor: searchVisitor.visitor(_:))	}
			searchResultCoordinates = searchVisitor.searchResultCoordinates
		}
		
		var changes = rebuildShadowTable()
		let reloads = searchResultCoordinates.compactMap { $0.row.shadowTableIndex }
		changes.append(OutlineElementChanges(section: .rows, reloads: Set(reloads)))
		outlineElementsDidChange(changes)
	}
		
	public func nextSearchResult() {
		guard searchResultCoordinates.count > 0 else { return }
		
		let nextResult: Int
		if currentSearchResult + 1 < searchResultCoordinates.count {
			nextResult = currentSearchResult + 1
		} else {
			nextResult = 0
		}
		
		changeSearchResult(nextResult)
	}
	
	public func previousSearchResult() {
		guard searchResultCoordinates.count > 0 else { return }
		
		let previousResult: Int
		if currentSearchResult - 1 >= 0 {
			previousResult = currentSearchResult - 1
		} else {
			previousResult = searchResultCoordinates.count - 1
		}
		
		changeSearchResult(previousResult)
	}
	
	public func endSearching() {
		isSearching = .notSearching

		clearSearchResults()
		
		let oldShadowTable = shadowTable
		var changes = rebuildShadowTable()

		if let deletes = changes.deletes {
			let reloads = deletes.compactMap { (oldShadowTable?[$0].parent as? Row)?.shadowTableIndex }
			changes.append(OutlineElementChanges(section: .rows, reloads: Set(reloads)))
		}
		
		outlineElementsDidChange(changes)
	}
	
	func createNotes(rows: [Row], textRowStrings: TextRowStrings?) -> ([Row], Int?) {
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let textRow = rows.first?.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}

		var impacted = [Row]()
		for row in rows {
			if let textRow = row.textRow, textRow.note == nil {
				textRow.note = NSAttributedString()
				impacted.append(row)
			}
		}
		
		endCloudKitBatchRequest()
		outlineBodyDidChange()
		
		let reloads = impacted.compactMap { $0.shadowTableIndex }
		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
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
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let textRow = rows.first?.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}

		var impacted = [Row: NSAttributedString]()
		for row in rows {
			if let textRow = row.textRow, textRow.note != nil {
				impacted[row] = textRow.note
				textRow.note = nil
			}
		}

		endCloudKitBatchRequest()
		outlineBodyDidChange()
		
		let reloads = impacted.keys.compactMap { $0.shadowTableIndex }
		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
		outlineElementsDidChange(changes)
		return (impacted, reloads.sorted().first)
	}
	
	func restoreNotes(_ notes: [Row: NSAttributedString]) {
		beginCloudKitBatchRequest()
		
		for (row, note) in notes {
			row.textRow?.note = note
		}

		endCloudKitBatchRequest()
		outlineBodyDidChange()
		
		let reloads = notes.keys.compactMap { $0.shadowTableIndex }
		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
		outlineElementsDidChange(changes)
	}
	
	@discardableResult
	func deleteRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) -> Int? {
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let textRow = rows.first?.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}

		var deletes = Set<Int>()

		for row in rows {
			guard let rowShadowTableIndex = row.shadowTableIndex else { return nil }
			deletes.insert(rowShadowTableIndex)
			row.parent?.removeRow(row)
		}

		endCloudKitBatchRequest()
		outlineBodyDidChange()
		
		var deletedRows = [Row]()
		
		let sortedDeletes = deletes.sorted(by: { $0 > $1 })
		for index in sortedDeletes {
			if let deletedRow = shadowTable?.remove(at: index) {
				deletedRows.append(deletedRow)
			}
		}
		
		guard let lowestShadowTableIndex = sortedDeletes.last else { return nil }
		resetShadowTableIndexes(startingAt: lowestShadowTableIndex)
		
		let reloads = rows.compactMap { ($0.parent as? Row)?.shadowTableIndex }
		let deleteSet = Set(deletes)
		let reloadSet = Set(reloads).subtracting(deleteSet)
		
		let changes = OutlineElementChanges(section: adjustedRowsSection, deletes: deleteSet, reloads: reloadSet)
		outlineElementsDidChange(changes)
		
		if deletedRows.contains(where: { $0.id == cursorRowID }) {
			if let firstDelete = deletes.first, firstDelete > 0 {
				return firstDelete - 1
			} else {
				return -1
			}
		} else {
			return nil
		}
	}
	
	func joinRows(topRow: Row, bottomRow: Row) {
		beginCloudKitBatchRequest()
		
		guard let topTextRow = topRow.textRow,
			  let topTopic = topTextRow.topic,
			  let topShadowTableIndex = topRow.shadowTableIndex,
			  let bottomTopic = bottomRow.textRow?.topic else { return }
		
		let mutableText = NSMutableAttributedString(attributedString: topTopic)
		mutableText.append(bottomTopic)
		topTextRow.topic = mutableText
		
		deleteRows([bottomRow])
		endCloudKitBatchRequest()
		
		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set([topShadowTableIndex]))
		outlineElementsDidChange(changes)
	}
	
	func createRow(_ row: Row, beforeRow: Row, textRowStrings: TextRowStrings? = nil) -> Int? {
		beginCloudKitBatchRequest()
		
		if let beforeTextRow = beforeRow.textRow, let texts = textRowStrings {
			beforeTextRow.textRowStrings = texts
		}

		guard let parent = beforeRow.parent,
			  let index = parent.firstIndexOfRow(beforeRow),
			  let shadowTableIndex = beforeRow.shadowTableIndex else {
			return nil
		}
		
		parent.insertRow(row, at: index)
		var mutatingRow = row
		mutatingRow.parent = parent
		
		endCloudKitBatchRequest()
		outlineBodyDidChange()

		shadowTable?.insert(row, at: shadowTableIndex)
		resetShadowTableIndexes(startingAt: shadowTableIndex)
		let changes = OutlineElementChanges(section: adjustedRowsSection, inserts: [shadowTableIndex])
		outlineElementsDidChange(changes)
		
		return shadowTableIndex
	}
	
	func createRow(_ row: Row, afterRow: Row? = nil, textRowStrings: TextRowStrings? = nil) -> Int? {
		beginCloudKitBatchRequest()
		
		if let afterTextRow = afterRow?.textRow, let texts = textRowStrings {
			afterTextRow.textRowStrings = texts
		}
		
		if afterRow == nil {
			insertRow(row, at: 0)
			var mutatingRow = row
			mutatingRow.parent = self
		} else if afterRow?.isExpanded ?? true && !(afterRow?.rowCount == 0) {
			afterRow?.insertRow(row, at: 0)
			var mutatingRow = row
			mutatingRow.parent = afterRow
		} else if let afterRow = afterRow, let parent = afterRow.parent {
			let insertIndex = parent.firstIndexOfRow(afterRow) ?? -1
			parent.insertRow(row, at: insertIndex + 1)
			var mutatingRow = row
			mutatingRow.parent = afterRow.parent
		} else if let afterRow = afterRow {
			let insertIndex = firstIndexOfRow(afterRow) ?? -1
			insertRow(row, at: insertIndex + 1)
			var mutatingRow = row
			mutatingRow.parent = self
		} else {
			insertRow(row, at: 0)
			var mutatingRow = row
			mutatingRow.parent = self
		}
		
		endCloudKitBatchRequest()
		outlineBodyDidChange()
			
		let rowShadowTableIndex: Int
		if let afterRowShadowTableIndex = afterRow?.shadowTableIndex {
			rowShadowTableIndex = afterRowShadowTableIndex + 1
		} else {
			rowShadowTableIndex = 0
		}
		
		var reloads = [Int]()
		if let reload = afterRow?.shadowTableIndex {
			reloads.append(reload)
		}

		let inserts = [rowShadowTableIndex]
		shadowTable?.insert(row, at: rowShadowTableIndex)
		
		resetShadowTableIndexes(startingAt: afterRow?.shadowTableIndex ?? 0)
		let changes = OutlineElementChanges(section: adjustedRowsSection, inserts: Set(inserts), reloads: Set(reloads))
		outlineElementsDidChange(changes)

		return inserts[0]
	}

	@discardableResult
	func createRows(_ rows: [Row], afterRow: Row? = nil, textRowStrings: TextRowStrings? = nil, prefersEnd: Bool = false) -> Int? {
		beginCloudKitBatchRequest()
		
		if let afterTextRow = afterRow?.textRow, let texts = textRowStrings {
			afterTextRow.textRowStrings = texts
		}

		for row in rows.sortedByReverseDisplayOrder() {
			if afterRow == nil {
				if prefersEnd {
					appendRow(row)
				} else {
					insertRow(row, at: 0)
				}
				var mutatingRow = row
				mutatingRow.parent = self
			} else if let parent = row.parent, parent as? Row == afterRow {
				parent.insertRow(row, at: 0)
			} else if let parent = row.parent, let afterRow = afterRow {
				let insertIndex = parent.firstIndexOfRow(afterRow) ?? parent.rowCount - 1
				parent.insertRow(row, at: insertIndex + 1)
			} else if afterRow?.isExpanded ?? true && !(afterRow?.rowCount == 0) {
				afterRow?.insertRow(row, at: 0)
				var mutatingRow = row
				mutatingRow.parent = afterRow
			} else if let afterRow = afterRow, let parent = afterRow.parent {
				let insertIndex = parent.firstIndexOfRow(afterRow) ?? -1
				parent.insertRow(row, at: insertIndex + 1)
				var mutatingRow = row
				mutatingRow.parent = afterRow.parent
			} else if let afterRow = afterRow {
				let insertIndex = firstIndexOfRow(afterRow) ?? -1
				insertRow(row, at: insertIndex + 1)
				var mutatingRow = row
				mutatingRow.parent = self
			} else {
				insertRow(row, at: 0)
				var mutatingRow = row
				mutatingRow.parent = self
			}
		}
		
		endCloudKitBatchRequest()
		outlineBodyDidChange()
		
		var changes = rebuildShadowTable()
		
		var reloads = Set<Int>()
		if let reload = afterRow?.shadowTableIndex {
			reloads.insert(reload)
		}
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		
		outlineElementsDidChange(changes)
		
		let inserts = Array(changes.inserts ?? Set<Int>()).sorted()
		return inserts.count > 0 ? inserts[0] : nil
	}
	
	func splitRow(newRow: Row, row: Row, topic: NSAttributedString, cursorPosition: Int) -> Int? {
		guard let newTextRow = newRow.textRow, let textRow = row.textRow else { return nil }
		
		beginCloudKitBatchRequest()
		
		let newTopicRange = NSRange(location: cursorPosition, length: topic.length - cursorPosition)
		let newTopicText = topic.attributedSubstring(from: newTopicRange)
		newTextRow.topic = newTopicText
		
		let topicRange = NSRange(location: 0, length: cursorPosition)
		let topicText = topic.attributedSubstring(from: topicRange)
		textRow.topic = topicText

		let newCursorIndex = createRows([newRow], afterRow: row)
		
		endCloudKitBatchRequest()

		if let rowShadowTableIndex = textRow.shadowTableIndex {
			let reloadChanges = OutlineElementChanges(section: adjustedRowsSection, reloads: Set([rowShadowTableIndex]))
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
			let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: [shadowTableIndex])
			outlineElementsDidChange(changes)
		}
	}
	
	@discardableResult
	public func expand(rows: [Row]) -> [Row] {
		if rowCount == 1, let row = rows.first {
			expand(row: row)
			return [row]
		}
		return expandCollapse(rows: rows, isExpanded: true)
	}
	
	@discardableResult
	func collapse(rows: [Row]) -> [Row] {
		if rowCount == 1, let row = rows.first {
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
				visited.rows.forEach { $0.visit(visitor: expandVisitor) }
			}

			container.rows.forEach { $0.visit(visitor: expandVisitor(_:)) }
		}

		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		
		let reloads = Set(impacted.compactMap { $0.shadowTableIndex })
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
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
				visited.rows.forEach { $0.visit(visitor: collapseVisitor) }
			}

			if let row = container as? Row {
				reloads.append(row)
			}
			
			container.rows.forEach {
				reloads.append($0)
				$0.visit(visitor: collapseVisitor(_:))
			}
		}
		
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
	
		let reloadIndexes = Set(reloads.compactMap { $0.shadowTableIndex })
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloadIndexes))
		
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
			if let rowIndex = row.parent?.firstIndexOfRow(row), rowIndex > 0 {
				return false
			}
		}
		return true
	}
	
	func indentRows(_ rows: [Row], textRowStrings: TextRowStrings?) -> [Row] {
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let textRow = rows.first?.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}
		
		let sortedRows = rows.sortedByDisplayOrder()

		var impacted = [Row]()
		var reloads = Set<Int>()

		for row in sortedRows {
			guard let container = row.parent,
				  let rowIndex = container.firstIndexOfRow(row),
				  rowIndex > 0,
				  var newParentRow = row.parent?.rows[rowIndex - 1],
				  let rowShadowTableIndex = row.shadowTableIndex,
				  let newParentRowShadowTableIndex = newParentRow.shadowTableIndex else { continue }

			impacted.append(row)
			expand(row: newParentRow)
			
			var mutatingRow = row
			mutatingRow.parent = newParentRow
			container.removeRow(mutatingRow)
			newParentRow.appendRow(mutatingRow)

			newParentRow.isExpanded = true

			reloads.insert(newParentRowShadowTableIndex)
			reloads.insert(rowShadowTableIndex)
		}
		
		endCloudKitBatchRequest()
		outlineBodyDidChange()
		
		func reloadVisitor(_ visited: Row) {
			if let index = visited.shadowTableIndex {
				reloads.insert(index)
			}
			if visited.isExpanded {
				visited.rows.forEach { $0.visit(visitor: reloadVisitor) }
			}
		}

		for row in impacted {
			if row.isExpanded {
				row.rows.forEach { $0.visit(visitor: reloadVisitor(_:)) }
			}
		}

		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: reloads)
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
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let textRow = rows.first?.textRow, let texts = textRowStrings {
			textRow.textRowStrings = texts
		}

		var impacted = [Row]()

		for row in rows.sortedWithDecendentsFiltered().reversed() {
			guard let oldParent = row.parent as? Row,
				  let oldRowIndex = oldParent.rows.firstIndex(of: row),
				  let newParent = oldParent.parent,
				  let oldParentIndex = newParent.rows.firstIndex(of: oldParent) else { continue }
			
			impacted.append(row)
			
			var siblingsToMove = [Row]()
			for i in (oldRowIndex + 1)..<oldParent.rowCount {
				siblingsToMove.append(oldParent.rows[i])
			}

			oldParent.removeRow(row)
			newParent.insertRow(row, at: oldParentIndex + 1)
			
			var mutatingRow = row
			mutatingRow.parent = oldParent.parent
		}

		endCloudKitBatchRequest()
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		let reloads = reloadsForParentAndChildren(rows: impacted)
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		outlineElementsDidChange(changes)
		
		return impacted
	}
	
	func moveRows(_ rowMoves: [RowMove], textRowStrings: TextRowStrings?) {
		beginCloudKitBatchRequest()
		
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
			rowMove.row.parent?.removeRow(rowMove.row)
			if let oldParentShadowTableIndex = (rowMove.row.parent as? Row)?.shadowTableIndex {
				oldParentReloads.insert(oldParentShadowTableIndex)
			}
			
			if rowMove.toChildIndex >= rowMove.toParent.rowCount {
				rowMove.toParent.appendRow(rowMove.row)
			} else {
				rowMove.toParent.insertRow(rowMove.row, at: rowMove.toChildIndex)
			}
		}

		endCloudKitBatchRequest()
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		var reloads = reloadsForParentAndChildren(rows: rowMoves.map { $0.row })
		reloads.formUnion(oldParentReloads)
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		outlineElementsDidChange(changes)
	}
	
	public func load() {
		guard rowsFile == nil else { return }
		rowsFile = RowsFile(outline: self)
		rowsFile!.load()
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
	
	func outlineDidDelete() {
		NotificationCenter.default.post(name: .DocumentDidDelete, object: Document.outline(self), userInfo: nil)
	}
	
}

// MARK: CustomDebugStringConvertible

extension Outline: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		var output = ""
		for row in rows {
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
		
		for child in row.rows {
			output.append(dumpRow(level: level + 1, row: child))
		}
		
		return output
	}
	
}

// MARK: CloudKit

extension Outline {
	
	func beginCloudKitBatchRequest() {
		batchCloudKitRequests += 1
	}
	
	func requestCloudKitUpdate(for entityID: EntityID) {
		guard let cloudKitManager = account?.cloudKitManager else { return }
		if batchCloudKitRequests > 0 {
			cloudKitRequestsIDs.insert(entityID)
		} else {
			guard let zoneID = zoneID else { return }
			cloudKitManager.addRequest(CloudKitActionRequest(zoneID: zoneID, id: entityID))
		}
	}

	func requestCloudKitUpdates(for entityIDs: [EntityID]) {
		beginCloudKitBatchRequest()
		for id in entityIDs {
			requestCloudKitUpdate(for: id)
		}
		endCloudKitBatchRequest()
	}

	func endCloudKitBatchRequest() {
		batchCloudKitRequests = batchCloudKitRequests - 1
		guard batchCloudKitRequests == 0, let cloudKitManager = account?.cloudKitManager, let zoneID = zoneID else { return }

		let requests = cloudKitRequestsIDs.map { CloudKitActionRequest(zoneID: zoneID, id: $0) }
		cloudKitManager.addRequests(Set(requests))
	}

	func apply(_ update: CloudKitOutlineUpdate) {
		if let record = update.saveOutlineRecord {
			applyOutlineRecord(record)
		}
		
		if keyedRows == nil {
			keyedRows = [EntityID: Row]()
		}
		
		for deleteRecordID in update.deleteRowRecordIDs {
			keyedRows?.removeValue(forKey: deleteRecordID)
		}
		
		var updatedRows = [Row]()
		
		for saveRowRecord in update.saveRowRecords {
			guard let entityID = EntityID(description: saveRowRecord.recordID.recordName) else { continue }

			var row: Row
			if let existingRow = keyedRows?[entityID] {
				row = existingRow
				updatedRows.append(row)
			} else {
				row = .text(TextRow(id: entityID))
			}

			row.textRow?.topicData = saveRowRecord[CloudKitOutlineZone.CloudKitRow.Fields.topicData] as? Data
			row.textRow?.noteData = saveRowRecord[CloudKitOutlineZone.CloudKitRow.Fields.noteData] as? Data
			row.textRow?.isComplete = saveRowRecord[CloudKitOutlineZone.CloudKitRow.Fields.isComplete] as? String == "1" ? true : false
			
			let rowOrder = saveRowRecord[CloudKitOutlineZone.CloudKitRow.Fields.rowOrder] as? [String]
			row.textRow?.rowOrder = rowOrder?.map { EntityID.row(id.accountID, id.documentUUID, $0) } ?? [EntityID]()
			
			keyedRows?[entityID] = row
		}
		
		guard beingViewedCount > 0 else { return }

		var reloadRows = [Row]()
		
		func reloadVisitor(_ visited: Row) {
			reloadRows.append(visited)
			visited.rows.forEach { $0.visit(visitor: reloadVisitor) }
		}

		for updatedRow in updatedRows {
			reloadRows.append(updatedRow)
			updatedRow.rows.forEach { $0.visit(visitor: reloadVisitor(_:)) }
		}
		
		var changes = rebuildShadowTable()
		let reloadIndexes = reloadRows.compactMap { $0.shadowTableIndex }
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloadIndexes)))
		outlineElementsDidChange(changes)
	}
	
	private func applyOutlineRecord(_ record: CKRecord) {
		if let shareReference = record.share {
			cloudKitShareRecordName = shareReference.recordID.recordName
		} else {
			cloudKitShareRecordName = nil
		}
		
		let newTitle = record[CloudKitOutlineZone.CloudKitOutline.Fields.title] as? String
		if title != newTitle {
			title = newTitle
			if beingViewedCount > 0 {
				outlineElementsDidChange(OutlineElementChanges(section: .title, reloads: Set([0])))
			}
		}

		ownerName = record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerName] as? String
		ownerEmail = record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerEmail] as? String
		ownerURL = record[CloudKitOutlineZone.CloudKitOutline.Fields.ownerURL] as? String
		
		let rowOrderRowUUIDs = record[CloudKitOutlineZone.CloudKitOutline.Fields.rowOrder] as? [String] ?? [String]()
		rowOrder = rowOrderRowUUIDs.map { EntityID.row(id.accountID, id.documentUUID, $0) }

		let cloudKitTagNames = record[CloudKitOutlineZone.CloudKitOutline.Fields.tagNames] as? [String] ?? [String]()
		let currentTagNames = Set(tags.map { $0.name })
		
		guard let account = account else { return }

		let cloudKitTagIDs = cloudKitTagNames.map({ account.createTag(name: $0) }).map({ $0.id })
		let oldTagIDs = tagIDs ?? [String]()
		tagIDs = cloudKitTagIDs

		let tagNamesToDelete = currentTagNames.subtracting(cloudKitTagNames)
		for tagNameToDelete in tagNamesToDelete {
			account.deleteTag(name: tagNameToDelete)
		}
		
		guard beingViewedCount > 0 else { return }

		var moves = Set<OutlineElementChanges.Move>()
		var inserts = Set<Int>()
		var deletes = Set<Int>()
		
		let diff = cloudKitTagIDs.difference(from: oldTagIDs).inferringMoves()
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
		
		let changes = OutlineElementChanges(section: .tags, deletes: deletes, inserts: inserts, moves: moves)
		outlineElementsDidChange(changes)
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

	private func documentSharingDidChange() {
		NotificationCenter.default.post(name: .DocumentSharingDidChange, object: Document.outline(self), userInfo: nil)
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
	
	private func changeSearchResult(_ changeToResult: Int) {
		var reloads = Set<Int>()
		
		let currentCoordinates = searchResultCoordinates[currentSearchResult]
		currentCoordinates.isCurrentResult = false
		if let shadowTableIndex = currentCoordinates.row.shadowTableIndex {
			reloads.insert(shadowTableIndex)
		}
		
		let changeToCoordinates = searchResultCoordinates[changeToResult]
		changeToCoordinates.isCurrentResult = true
		if let shadowTableIndex = changeToCoordinates.row.shadowTableIndex {
			reloads.insert(shadowTableIndex)
		}

		currentSearchResult = changeToResult
		
		outlineElementsDidChange(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
	}
	
	private func clearSearchResults() {
		currentSearchResult = 0

		func clearSearchVisitor(_ visited: Row) {
			var mutableVisited = visited
			mutableVisited.isPartOfSearchResult = false
			visited.rows.forEach { $0.visit(visitor: clearSearchVisitor) }
		}

		rows.forEach { $0.visit(visitor: clearSearchVisitor(_:)) }
		
		let reloads = Set(searchResultCoordinates.compactMap({ $0.row.shadowTableIndex }))
		searchResultCoordinates = .init()
		
		outlineElementsDidChange(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
	}
	
	private func completeUncomplete(rows: [Row], isComplete: Bool, textRowStrings: TextRowStrings?) -> ([Row], Int?) {
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let textRow = rows.first?.textRow, let textRowStrings = textRowStrings {
			textRow.textRowStrings = textRowStrings
		}
		
		var impacted = [Row]()
		
		for row in rows {
			if isComplete != row.isComplete {
				if isComplete {
					row.textRow?.complete()
				} else {
					row.textRow?.uncomplete()
				}
				impacted.append(row)
			}
		}
		
		endCloudKitBatchRequest()
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
					if visited.isExpanded {
						visited.rows.forEach { $0.visit(visitor: reloadVisitor) }
					}
				}

				if row.isExpanded {
					row.rows.forEach { $0.visit(visitor: reloadVisitor(_:)) }
				}
			}
		}
		
		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: reloads)
		outlineElementsDidChange(changes)
		return (impacted, nil)
	}

	private func isExpandAllUnavailable(container: RowContainer) -> Bool {
		if let row = container as? Row, row.isExpandable {
			return false
		}

		var unavailable = true
		
		func expandedRowVisitor(_ visited: Row) {
			for row in visited.rows {
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

		for row in container.rows {
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
			if isExpanded != row.isExpanded {
				var mutatingRow = row
				mutatingRow.isExpanded = isExpanded
				impacted.append(mutatingRow)
			}
		}
		
		outlineBodyDidChange()

		var changes = rebuildShadowTable()
		
		let reloads = Set(rows.compactMap { $0.shadowTableIndex })
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		
		outlineElementsDidChange(changes)
		return impacted
	}
	
	private func expand(row: Row) {
		guard !row.isExpanded, let rowShadowTableIndex = row.shadowTableIndex else { return }
		
		var mutatingRow = row
		mutatingRow.isExpanded = true

		outlineBodyDidChange()
		
		var shadowTableInserts = [Row]()

		func visitor(_ visited: Row) {
			let shouldFilter = isFiltered ?? false && visited.isComplete
			
			if !shouldFilter {
				shadowTableInserts.append(visited)

				if visited.isExpanded {
					visited.rows.forEach {
						$0.visit(visitor: visitor)
					}
				}
			}
		}

		row.rows.forEach { row in
			row.visit(visitor: visitor(_:))
		}
		
		var inserts = Set<Int>()
		for i in 0..<shadowTableInserts.count {
			let newIndex = i + rowShadowTableIndex + 1
			shadowTable?.insert(shadowTableInserts[i], at: newIndex)
			inserts.insert(newIndex)
		}
		
		resetShadowTableIndexes(startingAt: rowShadowTableIndex)
		let changes = OutlineElementChanges(section: adjustedRowsSection, inserts: inserts, reloads: [rowShadowTableIndex])
		outlineElementsDidChange(changes)
	}

	private func isCollapseAllUnavailable(container: RowContainer) -> Bool {
		if let row = container as? Row, row.isCollapsable {
			return false
		}
		
		var unavailable = true
		
		func collapsedRowVisitor(_ visited: Row) {
			for row in visited.rows {
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

		for row in container.rows {
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
		guard row.isExpanded else { return  }

		var mutatingRow = row
		mutatingRow.isExpanded = false
			
		outlineBodyDidChange()
		
		var reloads = Set<Int>()

		func visitor(_ visited: Row) {
			if let shadowTableIndex = visited.shadowTableIndex {
				reloads.insert(shadowTableIndex)
			}

			if visited.isExpanded {
				visited.rows.forEach {
					$0.visit(visitor: visitor)
				}
			}
		}
		
		row.rows.forEach { row in
			row.visit(visitor: visitor(_:))
		}
		
		shadowTable?.remove(atOffsets: IndexSet(reloads))
		
		guard let rowShadowTableIndex = row.shadowTableIndex else { return }
		resetShadowTableIndexes(startingAt: rowShadowTableIndex)
		let changes = OutlineElementChanges(section: adjustedRowsSection, deletes: reloads, reloads: Set([rowShadowTableIndex]))
		outlineElementsDidChange(changes)
	}
	
	private func rebuildShadowTable() -> OutlineElementChanges {
		guard let oldShadowTable = shadowTable else { return OutlineElementChanges(section: adjustedRowsSection) }
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
		
		return OutlineElementChanges(section: adjustedRowsSection, deletes: deletes, inserts: inserts, moves: moves)
	}
	
	private func rebuildTransientData() {
		let transient = TransientDataVisitor(isFiltered: isFiltered ?? false, isSearching: isSearching)
		rows.forEach { row in
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
				if visited.isExpanded {
					visited.rows.forEach { $0.visit(visitor: reloadVisitor) }
				}
			}

			if row.isExpanded {
				row.rows.forEach { $0.visit(visitor: reloadVisitor(_:)) }
			}
		}

		return reloads
	}
	
}

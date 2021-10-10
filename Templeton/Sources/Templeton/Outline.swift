//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import UIKit
import RSCore
import CloudKit

public extension Notification.Name {
	static let OutlineTagsDidChange = Notification.Name(rawValue: "OutlineTagsDidChange")
	static let OutlineElementsDidChange = Notification.Name(rawValue: "OutlineElementsDidChange")
	static let OutlineSearchWillBegin = Notification.Name(rawValue: "OutlineSearchWillBegin")
	static let OutlineSearchTextDidChange = Notification.Name(rawValue: "OutlineSearchTextDidChange")
	static let OutlineSearchWillEnd = Notification.Name(rawValue: "OutlineSearchWillEnd")
}

public final class Outline: RowContainer, OPMLImporter, Identifiable, Equatable, Codable {
	
	public enum Section: Int {
		case title = 0
		case tags = 1
		case rows = 2
		case backlinks = 3
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
	
	public struct UserInfoKeys {
		public static let searchText = "searchText"
	}
	
	public private(set) var isSearching = SearchState.notSearching
	public private(set) var searchText = ""

	public var adjustedRowsSection: Section {
		return isSearching == .notSearching ? Section.rows : Section.title
	}
	
	public var beingViewedCount = 0
	
	public var id: EntityID {
		didSet {
			documentMetaDataDidChange()
		}
	}

	public var syncID: String? {
		didSet {
			if syncID != oldValue {
				documentMetaDataDidChange()
			}
		}
	}
	
	public internal(set) var title: String?
	public internal(set) var ownerName: String?
	public internal(set) var ownerEmail: String?
	public internal(set) var ownerURL: String?

	public var created: Date? {
		didSet {
			if created != oldValue {
				documentMetaDataDidChange()
			}
		}
	}
	
	public var updated: Date? {
		didSet {
			if updated != oldValue {
				documentUpdatedDidChange()
				documentMetaDataDidChange()
			}
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
	
	public private(set) var documentLinks: [EntityID]?
	public private(set) var documentBacklinks: [EntityID]?
	
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
	
	private var collapseAllInOutlineUnavailable = true
	private var collapseAllInOutlineUnavailableNeedsUpdate = true
	public var isCollapseAllInOutlineUnavailable: Bool {
		if collapseAllInOutlineUnavailableNeedsUpdate {
			collapseAllInOutlineUnavailable = isCollapseAllUnavailable(container: self)
			collapseAllInOutlineUnavailableNeedsUpdate = false
		}
		return collapseAllInOutlineUnavailable
	}
	
	private var expandAllInOutlineUnavailable = true
	private var expandAllInOutlineUnavailableNeedsUpdate = true
	public var isExpandAllInOutlineUnavailable: Bool {
		if expandAllInOutlineUnavailableNeedsUpdate {
			expandAllInOutlineUnavailable = isExpandAllUnavailable(container: self)
			expandAllInOutlineUnavailableNeedsUpdate = false
		}
		return expandAllInOutlineUnavailable
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
				visited.isExpanded = expandedRows.contains(currentRow)
				currentRow = currentRow + 1
				visited.rows.forEach { $0.visit(visitor: expandedRowVisitor) }
			}

			rows.forEach { $0.visit(visitor: expandedRowVisitor(_:)) }
		}
	}
	
	public var cursorCoordinates: CursorCoordinates? {
		get {
			guard let rowID = selectionRowID,
				  let row = findRow(id: rowID.rowUUID),
				  let isInNotes = selectionIsInNotes,
				  let location = selectionLocation,
				  let length = selectionLength else {
				return nil
			}
			return CursorCoordinates(row: row, isInNotes: isInNotes, selection: NSRange(location: location, length: length))
		}
		set {
			if let coordinates = newValue {
				selectionRowID = .row(id.accountID, id.documentUUID, coordinates.row.id)
			} else {
				selectionRowID = nil
			}
			selectionIsInNotes = newValue?.isInNotes
			selectionLocation = newValue?.selection.location
			selectionLength = newValue?.selection.length
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
	
	public var images: [String: [Image]]?
	
	public private(set) var currentSearchResult = 0
	public var currentSearchResultRow: Row? {
		guard currentSearchResult < searchResultCoordinates.count else { return nil }
		return searchResultCoordinates[currentSearchResult].row
	}
	public var searchResultCount: Int {
		return searchResultCoordinates.count
	}
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case syncID = "syncID"
		case title = "title"
		case created = "created"
		case updated = "updated"
		case ownerName = "ownerName"
		case ownerEmail = "ownerEmail"
		case ownerURL = "ownerURL"
		case verticleScrollState = "verticleScrollState"
		case isFiltered = "isFiltered"
		case isNotesHidden = "isNotesHidden"
		case selectionRowID = "selectionRowID"
		case selectionIsInNotes = "selectionIsInNotes"
		case selectionLocation = "selectionLocation"
		case selectionLength = "selectionLength"
		case tagIDs = "tagIDS"
		case documentLinks = "documentLinks"
		case documentBacklinks = "documentBacklinks"
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
	
	var rowOrder: [String]?
	var keyedRows: [String: Row]? {
		didSet {
			if let keyedRows = keyedRows {
				for row in keyedRows.values {
					row.outline = self
				}
			}
		}
	}
	
	private var selectionRowID: EntityID?
	private var selectionIsInNotes: Bool?
	private var selectionLocation: Int?
	private var selectionLength: Int?

	private var tagIDs: [String]?
	
	private var rowsFile: RowsFile?
	private var imagesFile: ImagesFile?
	
	private var batchCloudKitRequests = 0
	private var cloudKitRequestsIDs = Set<EntityID>()
	
	private var searchResultCoordinates = [SearchResultCoordinates]()
	
	init(id: EntityID) {
		self.id = id
		self.created = Date()
		self.updated = Date()
		rowsFile = RowsFile(outline: self)
		imagesFile = ImagesFile(outline: self)
	}

	init(parentID: EntityID, title: String?) {
		self.id = .document(parentID.accountID, UUID().uuidString)
		self.title = title
		self.created = Date()
		self.updated = Date()
		rowsFile = RowsFile(outline: self)
		imagesFile = ImagesFile(outline: self)
	}

	public func reassignAccount(_ accountID: Int) {
		self.id = .document(accountID, id.documentUUID)
	}
	
	public func prepareForViewing() {
		rebuildTransientData()
	}
	
	public func findRow(id: String) -> Row? {
		return keyedRows?[id]
	}
	
	public func firstIndexOfRow(_ row: Row) -> Int? {
		return rows.firstIndex(of: row)
	}

	public func containsRow(_ row: Row) -> Bool {
		return rows.contains(row)
	}

	public func insertRow(_ row: Row, at: Int) {
		if rowOrder == nil {
			rowOrder = [String]()
		}

		if keyedRows == nil {
			keyedRows = [String: Row]()
		}

		rowOrder?.insert(row.id, at: at)
		keyedRows?[row.id] = row

		requestCloudKitUpdates(for: [id, row.entityID])
	}

	public func removeRow(_ row: Row) {
		rowOrder?.removeFirst(object: row.id)
		keyedRows?.removeValue(forKey: row.id)
		requestCloudKitUpdates(for: [id, row.entityID])
	}

	public func appendRow(_ row: Row) {
		if rowOrder == nil {
			rowOrder = [String]()
		}
		
		if keyedRows == nil {
			keyedRows = [String: Row]()
		}
		
		rowOrder?.append(row.id)
		keyedRows?[row.id] = row

		requestCloudKitUpdates(for: [id, row.entityID])
	}
	
	public func createTag(_ tag: Tag) {
		guard !hasTag(tag) else {
			return
		}
		
		if tagIDs == nil {
			tagIDs = [String]()
		}
		tagIDs!.append(tag.id)
		self.updated = Date()
		
		outlineTagsDidChange()

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

		outlineTagsDidChange()
		
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
	
	public func printDoc() -> NSAttributedString {
		let print = NSMutableAttributedString()
		load()
		
		appendPrintTitle(attrString: print)
		
		let visitor = PrintDocVisitor()
		rows.forEach {
			$0.visit(visitor: visitor.visitor)
		}
		print.append(visitor.print)

		unload()
		return print
	}
	
	public func printList() -> NSAttributedString {
		let print = NSMutableAttributedString()
		load()
		
		appendPrintTitle(attrString: print)
		
		rows.forEach {
			let visitor = PrintListVisitor()
			$0.visit(visitor: visitor.visitor)
			print.append(visitor.print)
		}

		unload()
		return print
	}
	
	public func string() -> String {
		loadRows()
		
		var string = "\(title ?? "")\n\n"
		rows.forEach {
			let visitor = StringVisitor()
			$0.visit(visitor: visitor.visitor)
			string.append(visitor.string)
			string.append("\n")
		}
		
		unloadRows()
		return string
	}
	
	public func markdownDoc() -> String {
		loadRows()
		
		var md = "# \(title ?? "")"
		let visitor = MarkdownDocVisitor()
		rows.forEach {
			$0.visit(visitor: visitor.visitor)
		}
		md.append(visitor.markdown)

		unloadRows()
		return md
	}
	
	public func markdownList() -> String {
		loadRows()
		
		var md = "# \(title ?? "")\n\n"
		rows.forEach {
			let visitor = MarkdownListVisitor()
			$0.visit(visitor: visitor.visitor)
			md.append(visitor.markdown)
			md.append("\n")
		}
		
		unloadRows()
		return md
	}
	
	public func opml(indentLevel: Int = 0) -> String {
		loadRows()

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
		rows.forEach {
			let visitor = OPMLVisitor()
			$0.visit(visitor: visitor.visitor)
			opml.append(visitor.opml)
		}
		opml.append("</body>\n")
		opml.append("</opml>\n")

		unloadRows()
		return opml
	}
	
	public func update(title: String) {
		self.title = title
		updated = Date()
		documentTitleDidChange()
		requestCloudKitUpdate(for: id)
	}
	
	public func update(ownerName: String?, ownerEmail: String?, ownerURL: String?) {
		self.ownerName = ownerName
		self.ownerEmail = ownerEmail
		self.ownerURL = ownerURL
		updated = Date()
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
		
		if let reloads = shadowTable?.filter({ !$0.isNoteEmpty }).compactMap({ $0.shadowTableIndex }) {
			return OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
		} else {
			return OutlineElementChanges(section: adjustedRowsSection)
		}
	}
	
	public func isCreateNotesUnavailable(rows: [Row]) -> Bool {
		return rows.isEmpty
	}
	
	public func beginSearching(for searchText: String? = nil) {
		isSearching = .beginSearch
		outlineSearchWillBegin()

		guard searchText == nil else {
			search(for: searchText!)
			return
		}
		
		var changes = rebuildShadowTable()

		if let inserts = changes.inserts {
			let reloads = inserts.compactMap { (shadowTable?[$0].parent as? Row)?.shadowTableIndex }
			changes.append(OutlineElementChanges(section: .rows, reloads: Set(reloads)))
		}
		
		outlineElementsDidChange(changes)
	}
	
	public func search(for searchText: String) {
		self.searchText = searchText
		
		clearSearchResults()
		
		if searchText.isEmpty {
			isSearching = .beginSearch
		} else {
			isSearching = .searching
			let searchVisitor = SearchResultVisitor(searchText: searchText, isFiltered: isFiltered ?? false, isNotesHidden: isNotesHidden ?? false)
			rows.forEach { $0.visit(visitor: searchVisitor.visitor(_:))	}
			searchResultCoordinates = searchVisitor.searchResultCoordinates
		}
		
		outlineSearchTextDidChange(searchText)
		
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
		clearSearchResults()
		outlineSearchWillEnd()
		isSearching = .notSearching

		guard beingViewedCount > 0 else { return }
		
		var changes = rebuildShadowTable()

		// Reload any rows that should be collapsed so that thier disclosure is in the correct position
		if let reloads = shadowTable?.filter({ !$0.isExpanded }).compactMap({ $0.shadowTableIndex }) {
			changes.append(OutlineElementChanges(section: .rows, reloads: Set(reloads)))
		}
		
		outlineElementsDidChange(changes)
	}
	
	func findImages(rowID: String) -> [Image]? {
		return images?[rowID]
	}
	
	func updateImages(rowID: String, images: [Image]?) {
		guard self.images?[rowID] != images else { return }
		
		if self.images == nil {
			self.images = [String: [Image]]()
		}
		
		if images?.isEmpty ?? true {
			self.images?.removeValue(forKey: rowID)
		} else {
			self.images?[rowID] = images
		}
		
		imagesFile?.markAsDirty()
	}
	
	func createNotes(rows: [Row], rowStrings: RowStrings?) -> ([Row], Int?) {
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}

		var impacted = [Row]()
		for row in rows {
			if row.note == nil {
				row.note = NSAttributedString()
				impacted.append(row)
			}
		}
		
		endCloudKitBatchRequest()
		outlineContentDidChange()
		
		let reloads = impacted.compactMap { $0.shadowTableIndex }
		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
		outlineElementsDidChange(changes)
		return (impacted, reloads.sorted().first)
	}
	
	public func isDeleteNotesUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if !row.isNoteEmpty {
				return false
			}
		}
		return true
	}
	
	@discardableResult
	func deleteNotes(rows: [Row], rowStrings: RowStrings?) -> ([Row: NSAttributedString], Int?) {
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}

		var impacted = [Row: NSAttributedString]()
		for row in rows {
			if row.note != nil {
				impacted[row] = row.note
				row.note = nil
			}
		}

		endCloudKitBatchRequest()
		outlineContentDidChange()
		
		let reloads = impacted.keys.compactMap { $0.shadowTableIndex }
		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
		outlineElementsDidChange(changes)
		return (impacted, reloads.sorted().first)
	}
	
	func restoreNotes(_ notes: [Row: NSAttributedString]) {
		beginCloudKitBatchRequest()
		
		for (row, note) in notes {
			row.note = note
		}

		endCloudKitBatchRequest()
		outlineContentDidChange()
		
		let reloads = notes.keys.compactMap { $0.shadowTableIndex }
		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
		outlineElementsDidChange(changes)
	}
	
	@discardableResult
	func deleteRows(_ rows: [Row], rowStrings: RowStrings? = nil) -> Int? {
		collapseAllInOutlineUnavailableNeedsUpdate = true
		
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}

		var deletes = Set<Int>()

		for row in rows {
			row.parent?.removeRow(row)
			guard let rowShadowTableIndex = row.shadowTableIndex else { continue }
			deletes.insert(rowShadowTableIndex)
		}

		deleteLinkRelationships(for: rows)
		endCloudKitBatchRequest()
		outlineContentDidChange()
		
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
		
		if deletedRows.contains(where: { $0.id == selectionRowID?.rowUUID }) {
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
		
		guard let topTopic = topRow.topic,
			  let topShadowTableIndex = topRow.shadowTableIndex,
			  let bottomTopic = bottomRow.topic else { return }
		
		let mutableText = NSMutableAttributedString(attributedString: topTopic)
		mutableText.append(bottomTopic)
		topRow.topic = mutableText
		
		deleteRows([bottomRow])
		endCloudKitBatchRequest()
		
		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set([topShadowTableIndex]))
		outlineElementsDidChange(changes)
	}
	
	func createRow(_ row: Row, beforeRow: Row, rowStrings: RowStrings? = nil) -> Int? {
		beginCloudKitBatchRequest()
		
		if let texts = rowStrings {
			updateRowStrings(beforeRow, texts)
		}

		guard let parent = beforeRow.parent,
			  let index = parent.firstIndexOfRow(beforeRow),
			  let shadowTableIndex = beforeRow.shadowTableIndex else {
			return nil
		}
		
		parent.insertRow(row, at: index)
		row.parent = parent
		
		createLinkRelationships(for: [row])
		endCloudKitBatchRequest()
		outlineContentDidChange()

		shadowTable?.insert(row, at: shadowTableIndex)
		resetShadowTableIndexes(startingAt: shadowTableIndex)
		let changes = OutlineElementChanges(section: adjustedRowsSection, inserts: [shadowTableIndex])
		outlineElementsDidChange(changes)
		
		return shadowTableIndex
	}
	
	func createRow(_ row: Row, afterRow: Row? = nil, rowStrings: RowStrings? = nil) -> Int? {
		beginCloudKitBatchRequest()
		
		if let afterRow = afterRow, let texts = rowStrings {
			updateRowStrings(afterRow, texts)
		}
		
		if afterRow == nil {
			insertRow(row, at: 0)
			row.parent = self
		} else if afterRow?.isExpanded ?? true && !(afterRow?.rowCount == 0) {
			afterRow?.insertRow(row, at: 0)
			row.parent = afterRow
		} else if let afterRow = afterRow, let parent = afterRow.parent {
			let insertIndex = parent.firstIndexOfRow(afterRow) ?? -1
			parent.insertRow(row, at: insertIndex + 1)
			row.parent = afterRow.parent
		} else if let afterRow = afterRow {
			let insertIndex = firstIndexOfRow(afterRow) ?? -1
			insertRow(row, at: insertIndex + 1)
			row.parent = self
		} else {
			insertRow(row, at: 0)
			row.parent = self
		}
		
		createLinkRelationships(for: [row])
		endCloudKitBatchRequest()
		outlineContentDidChange()
			
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
	func createRows(_ rows: [Row], afterRow: Row? = nil, rowStrings: RowStrings? = nil, prefersEnd: Bool = false) -> Int? {
		collapseAllInOutlineUnavailableNeedsUpdate = true
		
		beginCloudKitBatchRequest()
		
		if let afterRow = afterRow, let texts = rowStrings {
			updateRowStrings(afterRow, texts)
		}

		for row in rows.sortedByReverseDisplayOrder() {
			if afterRow == nil {
				if prefersEnd {
					appendRow(row)
				} else {
					insertRow(row, at: 0)
				}
				row.parent = self
			} else if let parent = row.parent, parent as? Row == afterRow {
				parent.insertRow(row, at: 0)
			} else if let parent = row.parent, let afterRow = afterRow {
				let insertIndex = parent.firstIndexOfRow(afterRow) ?? parent.rowCount - 1
				parent.insertRow(row, at: insertIndex + 1)
			} else if afterRow?.isExpanded ?? true && !(afterRow?.rowCount == 0) {
				afterRow?.insertRow(row, at: 0)
				row.parent = afterRow
			} else if let afterRow = afterRow, let parent = afterRow.parent {
				let insertIndex = parent.firstIndexOfRow(afterRow) ?? -1
				parent.insertRow(row, at: insertIndex + 1)
				row.parent = afterRow.parent
			} else if let afterRow = afterRow {
				let insertIndex = firstIndexOfRow(afterRow) ?? -1
				insertRow(row, at: insertIndex + 1)
				row.parent = self
			} else {
				insertRow(row, at: 0)
				row.parent = self
			}
		}
		
		createLinkRelationships(for: rows)
		endCloudKitBatchRequest()
		outlineContentDidChange()
		
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
	
	func createRowInside(_ row: Row, afterRow: Row, rowStrings: RowStrings? = nil) -> Int? {
		beginCloudKitBatchRequest()
		
		if let texts = rowStrings {
			updateRowStrings(afterRow, texts)
		}
		
		afterRow.insertRow(row, at: 0)
		row.parent = afterRow
		
		createLinkRelationships(for: [row])
		endCloudKitBatchRequest()
		outlineContentDidChange()
			
		let rowShadowTableIndex: Int
		if let afterRowShadowTableIndex = afterRow.shadowTableIndex {
			rowShadowTableIndex = afterRowShadowTableIndex + 1
		} else {
			rowShadowTableIndex = 0
		}
		
		var reloads = [Int]()
		if let reload = afterRow.shadowTableIndex {
			reloads.append(reload)
		}

		let inserts = [rowShadowTableIndex]
		shadowTable?.insert(row, at: rowShadowTableIndex)
		
		resetShadowTableIndexes(startingAt: afterRow.shadowTableIndex ?? 0)
		let changes = OutlineElementChanges(section: adjustedRowsSection, inserts: Set(inserts), reloads: Set(reloads))
		outlineElementsDidChange(changes)

		return inserts[0]
	}

	public func isCreateRowOutsideUnavailable(rows: [Row]) -> Bool {
		return isOutdentRowsUnavailable(rows: rows)
	}
	
	func createRowOutside(_ row: Row, afterRow: Row, rowStrings: RowStrings? = nil) -> Int? {
		beginCloudKitBatchRequest()
		
		if let texts = rowStrings {
			updateRowStrings(afterRow, texts)
		}
		
		guard let afterParentRow = afterRow.parent as? Row,
			  let afterParentRowParent = afterParentRow.parent,
			  let index = afterParentRowParent.firstIndexOfRow(afterParentRow) else {
			return nil
		}
		
		afterParentRowParent.insertRow(row, at: index + 1)
		row.parent = afterParentRowParent

		createLinkRelationships(for: [row])
		endCloudKitBatchRequest()
		outlineContentDidChange()

		outlineElementsDidChange(rebuildShadowTable())
		return row.shadowTableIndex
	}

	func duplicateRows(_ rows: [Row]) -> [Row] {
		beginCloudKitBatchRequest()

		var newRows = [Row]()
		var idDict = [String: Row]()
		
		let sortedRows = rows.sortedWithDecendentsFiltered().sortedByReverseDisplayOrder()
		guard let afterRow = sortedRows.first else { return newRows }
		
		func duplicatingVisitor(_ visited: Row) {
			let newRow = visited.duplicate(newOutline: self)
			newRow.rowOrder = [String]()
			
			if let parentRow = visited.parent as? Row {
				newRow.parent = idDict[parentRow.id] ?? visited.parent
			} else {
				newRow.parent = self
			}
			
			let insertIndex = newRow.parent!.firstIndexOfRow(afterRow) ?? newRow.parent!.rowCount - 1
			newRow.parent!.insertRow(newRow, at: insertIndex + 1)

			newRows.append(newRow)
			idDict[visited.id] = newRow
			
			visited.rows.forEach { $0.visit(visitor: duplicatingVisitor) }
		}

		sortedRows.forEach { $0.visit(visitor: duplicatingVisitor(_:)) }
		
		endCloudKitBatchRequest()
		outlineContentDidChange()
		outlineElementsDidChange(rebuildShadowTable())

		return newRows
	}

	func splitRow(newRow: Row, row: Row, topic: NSAttributedString, cursorPosition: Int) -> Int? {
		beginCloudKitBatchRequest()
		
		let newTopicRange = NSRange(location: cursorPosition, length: topic.length - cursorPosition)
		let newTopicText = topic.attributedSubstring(from: newTopicRange)
		newRow.topic = newTopicText
		
		let topicRange = NSRange(location: 0, length: cursorPosition)
		let topicText = topic.attributedSubstring(from: topicRange)
		row.topic = topicText

		let newCursorIndex = createRows([newRow], afterRow: row)
		
		endCloudKitBatchRequest()

		if let rowShadowTableIndex = row.shadowTableIndex {
			let reloadChanges = OutlineElementChanges(section: adjustedRowsSection, reloads: Set([rowShadowTableIndex]))
			outlineElementsDidChange(reloadChanges)
		}

		return newCursorIndex
	}

	func updateRow(_ row: Row, rowStrings: RowStrings?, applyChanges: Bool) {
		if let texts = rowStrings {
			updateRowStrings(row, texts)
		}
		
		outlineContentDidChange()
		
		if applyChanges {
			guard let shadowTableIndex = row.shadowTableIndex else { return }
			let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: [shadowTableIndex])
			outlineElementsDidChange(changes)
		}
	}
	
	@discardableResult
	public func expand(rows: [Row]) -> [Row] {
		expandAllInOutlineUnavailableNeedsUpdate = true
		collapseAllInOutlineUnavailableNeedsUpdate = true

		if rowCount == 1, let row = rows.first {
			expand(row: row)
			return [row]
		}
		
		return expandCollapse(rows: rows, isExpanded: true)
	}
	
	@discardableResult
	func collapse(rows: [Row]) -> [Row] {
		expandAllInOutlineUnavailableNeedsUpdate = true
		collapseAllInOutlineUnavailableNeedsUpdate = true
		
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
		expandAllInOutlineUnavailableNeedsUpdate = true
		collapseAllInOutlineUnavailableNeedsUpdate = true

		var impacted = [Row]()
		
		for container in containers {
			if let row = container as? Row, row.isExpandable {
				row.isExpanded = true
				impacted.append(row)
			}
			
			func expandVisitor(_ visited: Row) {
				if visited.isExpandable {
					visited.isExpanded = true
					impacted.append(visited)
				}
				visited.rows.forEach { $0.visit(visitor: expandVisitor) }
			}

			container.rows.forEach { $0.visit(visitor: expandVisitor(_:)) }
		}

		outlineViewPropertyDidChange()

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
		expandAllInOutlineUnavailableNeedsUpdate = true
		collapseAllInOutlineUnavailableNeedsUpdate = true

		var impacted = [Row]()
		var reloads = [Row]()

		for container in containers {
			if let row = container as? Row, row.isCollapsable {
				row.isExpanded = false
				impacted.append(row)
			}
			
			func collapseVisitor(_ visited: Row) {
				if visited.isCollapsable {
					visited.isExpanded = false
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
		
		outlineViewPropertyDidChange()

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
	func complete(rows: [Row], rowStrings: RowStrings?) -> ([Row], Int?) {
		return completeUncomplete(rows: rows, isComplete: true, rowStrings: rowStrings)
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
	func uncomplete(rows: [Row], rowStrings: RowStrings?) -> [Row] {
		let (impacted, _) = completeUncomplete(rows: rows, isComplete: false, rowStrings: rowStrings)
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
	
	func indentRows(_ rows: [Row], rowStrings: RowStrings?) -> [Row] {
		collapseAllInOutlineUnavailableNeedsUpdate = true

		beginCloudKitBatchRequest()
		
		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}
		
		let sortedRows = rows.sortedByDisplayOrder()

		var impacted = [Row]()
		var reloads = Set<Int>()
		var deletes = Set<Int>()

		for row in sortedRows {
			guard let container = row.parent,
				  let rowIndex = container.firstIndexOfRow(row),
				  rowIndex > 0,
				  let newParentRow = row.parent?.rows[rowIndex - 1],
				  let rowShadowTableIndex = row.shadowTableIndex else { continue }

			impacted.append(row)
			expand(row: newParentRow)
			
			row.parent = newParentRow
			container.removeRow(row)
			newParentRow.appendRow(row)

			newParentRow.isExpanded = true

			// If the new parent row doesn't have a shadow table index, it is because it is filtered
			if let newParentRowShadowTableIndex = newParentRow.shadowTableIndex {
				reloads.insert(newParentRowShadowTableIndex)
				reloads.insert(rowShadowTableIndex)
			} else {
				shadowTable?.remove(at: rowShadowTableIndex)
				deletes.insert(rowShadowTableIndex)
			}
		}
		
		endCloudKitBatchRequest()
		outlineContentDidChange()
		
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

		let changes = OutlineElementChanges(section: adjustedRowsSection, deletes: deletes, reloads: reloads)
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
	func outdentRows(_ rows: [Row], rowStrings: RowStrings?) -> [Row] {
		collapseAllInOutlineUnavailableNeedsUpdate = true

		beginCloudKitBatchRequest()
		
		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
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
			
			row.parent = oldParent.parent
		}

		endCloudKitBatchRequest()
		outlineContentDidChange()

		var changes = rebuildShadowTable()
		let reloads = reloadsForParentAndChildren(rows: impacted)
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		outlineElementsDidChange(changes)
		
		return impacted
	}
	
	public func isMoveRowsUpUnavailable(rows: [Row]) -> Bool {
		guard let first = rows.sortedByDisplayOrder().first else { return true }
		
		for row in rows {
			if !first.hasSameParent(row) {
				return true
			}
		}
		
		guard let index = first.parent?.rows.firstIndex(of: first) else { return true }
		
		return index == 0
	}

	func moveRowsUp(_ rows: [Row], rowStrings: RowStrings?) {
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}

		for row in rows.sortedByDisplayOrder() {
			if let parent = row.parent, let index = parent.firstIndexOfRow(row), index - 1 > -1 {
				parent.removeRow(row)
				parent.insertRow(row, at: index - 1)
			}
		}
		
		endCloudKitBatchRequest()
		outlineContentDidChange()
		outlineElementsDidChange(rebuildShadowTable())
	}
	
	public func isMoveRowsDownUnavailable(rows: [Row]) -> Bool {
		guard let last = rows.sortedByDisplayOrder().last else { return true }
		
		for row in rows {
			if !last.hasSameParent(row) {
				return true
			}
		}
		
		guard let index = last.parent?.rows.firstIndex(of: last) else { return true }
		
		return index == (last.parent?.rowCount ?? -1) - 1
	}

	func moveRowsDown(_ rows: [Row], rowStrings: RowStrings?) {
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}

		for row in rows.sortedByReverseDisplayOrder() {
			if let parent = row.parent, let index = parent.firstIndexOfRow(row), index + 1 < parent.rowCount {
				parent.removeRow(row)
				parent.insertRow(row, at: index + 1)
			}
		}
		
		endCloudKitBatchRequest()
		outlineContentDidChange()
		outlineElementsDidChange(rebuildShadowTable())
	}
	
	public func isMoveRowsLeftUnavailable(rows: [Row]) -> Bool {
		return isOutdentRowsUnavailable(rows: rows)
	}
	
	public func isMoveRowsRightUnavailable(rows: [Row]) -> Bool {
		return isIndentRowsUnavailable(rows: rows)
	}
	
	func moveRows(_ rowMoves: [RowMove], rowStrings: RowStrings?) {
		beginCloudKitBatchRequest()
		
		if rowMoves.count == 1, let row = rowMoves.first?.row, let texts = rowStrings {
			updateRowStrings(row, texts)
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
		outlineContentDidChange()

		var changes = rebuildShadowTable()
		var reloads = reloadsForParentAndChildren(rows: rowMoves.map { $0.row })
		reloads.formUnion(oldParentReloads)
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		outlineElementsDidChange(changes)
	}
	
	public func load() {
		loadRows()
		loadImages()
	}
	
	public func unload() {
		unloadRows()
		unloadImages()
	}
	
	public func loadRows() {
		guard rowsFile == nil else { return }
		rowsFile = RowsFile(outline: self)
		rowsFile?.load()
	}
	
	public func unloadRows() {
		rowsFile?.save()
		
		guard beingViewedCount < 1 else { return }
		
		rowsFile?.suspend()
		rowsFile = nil
		shadowTable = nil
		rowOrder = nil
		keyedRows = nil
	}
	
	public func loadImages() {
		guard imagesFile == nil else { return }
		imagesFile = ImagesFile(outline: self)
		imagesFile?.load()
	}
	
	public func unloadImages() {
		imagesFile?.save()
		
		guard beingViewedCount < 1 else { return }
		
		imagesFile?.suspend()
		imagesFile = nil
		images = nil
	}
	
	public func suspend() {
		rowsFile?.suspend()
		imagesFile?.suspend()
	}
	
	public func resume() {
		rowsFile?.resume()
		imagesFile?.resume()
	}
	
	public func save() {
		rowsFile?.save()
		imagesFile?.save()
	}
	
	public func forceSave() {
		if rowsFile == nil {
			rowsFile = RowsFile(outline: self)
		}
		rowsFile?.markAsDirty()
		rowsFile?.save()
		
		imagesFile?.markAsDirty()
		imagesFile?.save()
	}
	
	public func delete() {
		for link in documentLinks ?? [EntityID]() {
			if let outline = AccountManager.shared.findDocument(link)?.outline {
				outline.deleteBacklink(id)
			}
		}
		
		documentLinks = nil
		
		if rowsFile == nil {
			rowsFile = RowsFile(outline: self)
		}
		rowsFile?.delete()
		rowsFile = nil
		
		if imagesFile == nil {
			imagesFile = ImagesFile(outline: self)
		}
		imagesFile?.delete()
		imagesFile = nil

		outlineDidDelete()
	}
	
	public func duplicate() -> Outline {
		let outline = Outline(id: .document(id.accountID, UUID().uuidString))

		outline.title = title
		outline.ownerName = ownerName
		outline.ownerEmail = ownerEmail
		outline.ownerURL = ownerURL
		outline.isFiltered = isFiltered
		outline.isNotesHidden = isNotesHidden
		outline.tagIDs = tagIDs
		outline.documentLinks = documentLinks
		
		for linkedDocumentID in outline.documentLinks ?? [EntityID]() {
			if let linkedOutline = AccountManager.shared.findDocument(linkedDocumentID)?.outline {
				linkedOutline.createBacklink(outline.id)
			}
		}
		
		guard let keyedRows = keyedRows else { return outline }

		var rowIDMap = [String: String]()
		var newKeyedRows = [String: Row]()
		for key in keyedRows.keys {
			if let row = keyedRows[key] {
				let duplicateRow = row.duplicate(newOutline: outline)
				newKeyedRows[duplicateRow.id] = duplicateRow
				rowIDMap[row.id] = duplicateRow.id
			}
		}
		
		var newRowOrder = [String]()
		for orderKey in rowOrder ?? [String]() {
			if let newKey = rowIDMap[orderKey] {
				newRowOrder.append(newKey)
			}
		}
		outline.rowOrder = newRowOrder
		
		var updatedNewKeyedRows = [String: Row]()
		for key in newKeyedRows.keys {
			if let newKeyedRow = newKeyedRows[key] {
				var updatedRowOrder = [String]()
				for orderKey in newKeyedRow.rowOrder {
					if let newKey = rowIDMap[orderKey] {
						updatedRowOrder.append(newKey)
					}
				}
				newKeyedRow.rowOrder = updatedRowOrder
				updatedNewKeyedRows[newKeyedRow.id] = newKeyedRow
			}
			
		}
		
		outline.keyedRows = updatedNewKeyedRows
		
		return outline
	}
	
	public func updateAllLinkRelationships() {
		var newDocumentLinks = [EntityID]()
		
		func linkVisitor(_ visited: Row) {
			if let topic = visited.topic {
				newDocumentLinks.append(contentsOf: extractLinkToIDs(topic))
			}
			if let note = visited.note {
				newDocumentLinks.append(contentsOf: extractLinkToIDs(note))
			}
			visited.rows.forEach { $0.visit(visitor: linkVisitor) }
		}

		rows.forEach { $0.visit(visitor: linkVisitor(_:)) }
		
		let currentDocumentLinks = documentLinks ?? [EntityID]()
		let diff = newDocumentLinks.difference(from: currentDocumentLinks)
		processLinkDiff(diff)
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
		for id in entityIDs {
			requestCloudKitUpdate(for: id)
		}
	}

	func endCloudKitBatchRequest() {
		batchCloudKitRequests = batchCloudKitRequests - 1
		guard batchCloudKitRequests == 0, let cloudKitManager = account?.cloudKitManager, let zoneID = zoneID else { return }

		let requests = cloudKitRequestsIDs.map { CloudKitActionRequest(zoneID: zoneID, id: $0) }
		cloudKitManager.addRequests(Set(requests))
	}

	func apply(_ update: CloudKitOutlineUpdate) {
		var updatedRowIDs = Set<String>()
		
		if let record = update.saveOutlineRecord {
			let outlineUpdatedRows = applyOutlineRecord(record)
			updatedRowIDs.formUnion(outlineUpdatedRows)
		}
		
		if keyedRows == nil {
			keyedRows = [String: Row]()
		}
		
		for deleteRecordID in update.deleteRowRecordIDs {
			keyedRows?.removeValue(forKey: deleteRecordID.rowUUID)
		}
		
		for saveRecord in update.saveRowRecords {
			guard let entityID = EntityID(description: saveRecord.recordID.recordName) else { continue }

			var isExistingRecord = false
			var row: Row
			if let existingRow = keyedRows?[entityID.rowUUID] {
				row = existingRow
				isExistingRecord = true
			} else {
				row = Row(id: entityID.rowUUID)
			}

			if let recordSyncID = saveRecord[CloudKitOutlineZone.CloudKitRow.Fields.syncID] as? String, recordSyncID == row.syncID {
				continue
			}

			if isExistingRecord {
				updatedRowIDs.insert(row.id)
			}
			
			let updatedTopicData = saveRecord[CloudKitOutlineZone.CloudKitRow.Fields.topicData] as? Data
			row.topicData = updatedTopicData
			
			let updatedNoteData = saveRecord[CloudKitOutlineZone.CloudKitRow.Fields.noteData] as? Data
			row.noteData = updatedNoteData
			
			let updatedIsComplete = saveRecord[CloudKitOutlineZone.CloudKitRow.Fields.isComplete] as? String == "1" ? true : false
			row.isComplete = updatedIsComplete
			
			let newRowOrder = saveRecord[CloudKitOutlineZone.CloudKitRow.Fields.rowOrder] as? [String]
			
			row.rowOrder = newRowOrder ?? [String]()
			
			keyedRows?[entityID.rowUUID] = row
		}
		
		for deleteRecordID in update.deleteImageRecordIDs {
			if let row = keyedRows?[deleteRecordID.rowUUID] {
				row.deleteImage(id: deleteRecordID)
				updatedRowIDs.insert(deleteRecordID.rowUUID)
			}
		}
		
		for saveRecord in update.saveImageRecords {
			guard let saveRecordID = EntityID(description: saveRecord.recordID.recordName) else { continue }
			
			if let row = keyedRows?[saveRecordID.rowUUID],
			   let isInNotes = saveRecord[CloudKitOutlineZone.CloudKitImage.Fields.isInNotes] as? Bool,
			   let offset = saveRecord[CloudKitOutlineZone.CloudKitImage.Fields.offset] as? Int,
			   let asset = saveRecord[CloudKitOutlineZone.CloudKitImage.Fields.asset] as? CKAsset,
			   let fileURL = asset.fileURL,
			   let data = try? Data(contentsOf: fileURL) {

				let image = Image(id: saveRecordID, isInNotes: isInNotes, offset: offset, data: data)
				
				row.saveImage(image)
				updatedRowIDs.insert(saveRecordID.rowUUID)
			}
		}
		
		if !updatedRowIDs.isEmpty {
			rowsFile?.markAsDirty()
		}
		
		documentDidChangeBySync()
		
		guard beingViewedCount > 0 else { return }

		var reloadRows = [Row]()
		
		func reloadVisitor(_ visited: Row) {
			reloadRows.append(visited)
			visited.rows.forEach { $0.visit(visitor: reloadVisitor) }
		}

		for updatedRowID in updatedRowIDs {
			if let updatedRow = keyedRows?[updatedRowID] {
				reloadRows.append(updatedRow)
				updatedRow.rows.forEach { $0.visit(visitor: reloadVisitor(_:)) }
			}
		}
		
		var changes = rebuildShadowTable()
		let reloadIndexes = reloadRows.compactMap { $0.shadowTableIndex }
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloadIndexes)))
		outlineElementsDidChange(changes)
	}
	
	private func applyOutlineRecord(_ record: CKRecord) -> [String] {
		if let shareReference = record.share {
			cloudKitShareRecordName = shareReference.recordID.recordName
		} else {
			cloudKitShareRecordName = nil
		}

		if let recordSyncID = record[CloudKitOutlineZone.CloudKitOutline.Fields.syncID] as? String, recordSyncID == syncID {
			return []
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
		created = record[CloudKitOutlineZone.CloudKitOutline.Fields.created] as? Date
		updated = record[CloudKitOutlineZone.CloudKitOutline.Fields.updated] as? Date

		let newRowOrder = record[CloudKitOutlineZone.CloudKitOutline.Fields.rowOrder] as? [String] ?? [String]()
		
		var updatedRowIDs = [String]()
		
		//  We only count newly added children for reloading so that they can indent or outdent
		let rowDiff = newRowOrder.difference(from: rowOrder ?? [String]())
		for change in rowDiff {
			switch change {
			case .insert(_, let newRowID, _):
				updatedRowIDs.append(newRowID)
			default:
				break
			}
		}

		rowOrder = newRowOrder

		let documentLinkDescriptions = record[CloudKitOutlineZone.CloudKitOutline.Fields.documentLinks] as? [String] ?? [String]()
		documentLinks = documentLinkDescriptions.compactMap { EntityID(description: $0) }

		let documentBacklinkDescriptions = record[CloudKitOutlineZone.CloudKitOutline.Fields.documentBacklinks] as? [String] ?? [String]()
		documentBacklinks = documentBacklinkDescriptions.compactMap { EntityID(description: $0) }

		let cloudKitTagNames = record[CloudKitOutlineZone.CloudKitOutline.Fields.tagNames] as? [String] ?? [String]()
		let currentTagNames = Set(tags.map { $0.name })
		
		guard let account = account else { return updatedRowIDs }

		let cloudKitTagIDs = cloudKitTagNames.map({ account.createTag(name: $0) }).map({ $0.id })
		let oldTagIDs = tagIDs ?? [String]()
		tagIDs = cloudKitTagIDs

		let tagNamesToDelete = currentTagNames.subtracting(cloudKitTagNames)
		for tagNameToDelete in tagNamesToDelete {
			account.deleteTag(name: tagNameToDelete)
		}
		
		guard beingViewedCount > 0, isSearching == .notSearching else { return updatedRowIDs }

		var moves = Set<OutlineElementChanges.Move>()
		var inserts = Set<Int>()
		var deletes = Set<Int>()
		
		let tagDiff = cloudKitTagIDs.difference(from: oldTagIDs).inferringMoves()
		for change in tagDiff {
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
		outlineElementsDidChange(OutlineElementChanges(section: .backlinks, reloads: Set([0])))
		
		return updatedRowIDs
	}
	
}

// MARK: Helpers

extension Outline {
	
	private func documentDidChangeBySync() {
		NotificationCenter.default.post(name: .DocumentDidChangeBySync, object: Document.outline(self), userInfo: nil)
	}

	private func documentTitleDidChange() {
		NotificationCenter.default.post(name: .DocumentTitleDidChange, object: Document.outline(self), userInfo: nil)
	}

	private func documentUpdatedDidChange() {
		NotificationCenter.default.post(name: .DocumentUpdatedDidChange, object: Document.outline(self), userInfo: nil)
	}

	private func documentMetaDataDidChange() {
		NotificationCenter.default.post(name: .DocumentMetaDataDidChange, object: Document.outline(self), userInfo: nil)
	}

	private func documentSharingDidChange() {
		NotificationCenter.default.post(name: .DocumentSharingDidChange, object: Document.outline(self), userInfo: nil)
	}

	private func outlineContentDidChange() {
		self.updated = Date()
		requestCloudKitUpdate(for: id)
		rowsFile?.markAsDirty()
	}
	
	private func outlineViewPropertyDidChange() {
		documentMetaDataDidChange()
		rowsFile?.markAsDirty()
	}
	
	private func outlineTagsDidChange() {
		NotificationCenter.default.post(name: .OutlineTagsDidChange, object: self, userInfo: nil)
	}
	
	private func outlineElementsDidChange(_ changes: OutlineElementChanges) {
		var userInfo = [AnyHashable: Any]()
		userInfo[OutlineElementChanges.userInfoKey] = changes
		NotificationCenter.default.post(name: .OutlineElementsDidChange, object: self, userInfo: userInfo)
	}
	
	private func outlineSearchWillBegin() {
		NotificationCenter.default.post(name: .OutlineSearchWillBegin, object: self, userInfo: nil)
	}
	
	private func outlineSearchTextDidChange(_ searchText: String) {
		var userInfo = [AnyHashable: Any]()
		userInfo[UserInfoKeys.searchText] = searchText
		NotificationCenter.default.post(name: .OutlineSearchTextDidChange, object: self, userInfo: userInfo)
	}
	
	private func outlineSearchWillEnd() {
		NotificationCenter.default.post(name: .OutlineSearchWillEnd, object: self, userInfo: nil)
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
			visited.isPartOfSearchResult = false
			visited.rows.forEach { $0.visit(visitor: clearSearchVisitor) }
		}

		rows.forEach { $0.visit(visitor: clearSearchVisitor(_:)) }
		
		let reloads = Set(searchResultCoordinates.compactMap({ $0.row.shadowTableIndex }))
		searchResultCoordinates = .init()
		
		outlineElementsDidChange(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
	}
	
	private func completeUncomplete(rows: [Row], isComplete: Bool, rowStrings: RowStrings?) -> ([Row], Int?) {
		beginCloudKitBatchRequest()
		
		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}
		
		var impacted = [Row]()
		
		for row in rows {
			if isComplete != row.isComplete {
				if isComplete {
					row.complete()
				} else {
					row.uncomplete()
				}
				impacted.append(row)
			}
		}
		
		endCloudKitBatchRequest()
		outlineContentDidChange()
		
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
				row.isExpanded = isExpanded
				impacted.append(row)
			}
		}
		
		outlineViewPropertyDidChange()

		var changes = rebuildShadowTable()
		
		let reloads = Set(rows.compactMap { $0.shadowTableIndex })
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		
		outlineElementsDidChange(changes)
		return impacted
	}
	
	private func expand(row: Row) {
		guard !row.isExpanded, let rowShadowTableIndex = row.shadowTableIndex else { return }
		
		row.isExpanded = true

		outlineViewPropertyDidChange()
		
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

		row.isExpanded = false
			
		outlineViewPropertyDidChange()
		
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
			row.parent = self
			row.visit(visitor: transient.visitor(_:))
		}
		self.shadowTable = transient.shadowTable
	}
	
	private func resetShadowTableIndexes(startingAt: Int = 0) {
		guard let shadowTable = shadowTable else { return }
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
	
	private func deleteLinkRelationships(for rows: [Row]) {
		rows.forEach { row in
			if let topic = row.topic {
				extractLinkToIDs(topic).forEach { deleteLinkRelationship($0) }
			}
			if let note = row.note {
				extractLinkToIDs(note).forEach { deleteLinkRelationship($0) }
			}
		}
	}

	private func createLinkRelationships(for rows: [Row]) {
		rows.forEach { row in
			if let topic = row.topic {
				extractLinkToIDs(topic).forEach { createLinkRelationship($0) }
			}
			if let note = row.note {
				extractLinkToIDs(note).forEach { createLinkRelationship($0) }
			}
		}
	}

	private func updateRowStrings(_ row: Row, _ rowStrings: RowStrings) {
		switch rowStrings {
		case .topic(let topic):
			processLinkDiff(oldText: row.topic, newText: topic)
		case .note(let note):
			processLinkDiff(oldText: row.note, newText: note)
		case .both(let topic, let note):
			processLinkDiff(oldText: row.topic, newText: topic)
			processLinkDiff(oldText: row.note, newText: note)
		}

		row.rowStrings = rowStrings
	}
	
	private func processLinkDiff(oldText: NSAttributedString?, newText: NSAttributedString?) {
		let oldTextDocLinks = oldText != nil ? extractLinkToIDs(oldText!) : [EntityID]()
		let newTextDocLinks = newText != nil ? extractLinkToIDs(newText!) : [EntityID]()
		let topicDiff = newTextDocLinks.difference(from: oldTextDocLinks)
		processLinkDiff(topicDiff)
	}
	
	private func processLinkDiff(_ diff: CollectionDifference<EntityID>) {
		guard !diff.isEmpty else { return }
		
		for change in diff {
			switch change {
			case .insert(_, let entityID, _):
				createLinkRelationship(entityID)
			case .remove(_, let entityID, _):
				deleteLinkRelationship(entityID)
			}
		}

	}
	
	private func createLinkRelationship(_ entityID: EntityID) {
		guard let outline = AccountManager.shared.findDocument(entityID)?.outline else { return }
		
		outline.createBacklink(id)
		if documentLinks == nil {
			documentLinks = [EntityID]()
		}
		documentLinks?.append(entityID)

		documentMetaDataDidChange()
		requestCloudKitUpdate(for: id)
	}

	private func deleteLinkRelationship(_ entityID: EntityID) {
		guard let outline = AccountManager.shared.findDocument(entityID)?.outline else { return }

		outline.deleteBacklink(id)
		documentLinks?.removeFirst(object: entityID)

		documentMetaDataDidChange()
		requestCloudKitUpdate(for: id)
	}

	private func extractLinkToIDs(_ attrString: NSAttributedString) -> [EntityID] {
		var ids = [EntityID]()
		attrString.enumerateAttribute(.link, in:  NSRange(0..<attrString.length)) { value, range, stop in
			if let url = value as? URL, let id = EntityID(url: url) {
				ids.append(id)
			}
		}
		return ids
	}
	
	private func createBacklink(_ entityID: EntityID) {
		if documentBacklinks == nil {
			documentBacklinks = [EntityID]()
		}
		documentBacklinks?.append(entityID)
		documentMetaDataDidChange()
		if isSearching == .notSearching {
			outlineElementsDidChange(OutlineElementChanges(section: Section.backlinks, reloads: Set([0])))
		}
		requestCloudKitUpdate(for: id)
	}

	private func deleteBacklink(_ entityID: EntityID) {
		documentBacklinks?.removeFirst(object: entityID)
		documentMetaDataDidChange()
		if isSearching == .notSearching {
			outlineElementsDidChange(OutlineElementChanges(section: Section.backlinks, reloads: Set([0])))
		}
		requestCloudKitUpdate(for: id)
	}

	private func appendPrintTitle(attrString: NSMutableAttributedString) {
		if let title = title {
			let titleFont = UIFont.systemFont(ofSize: 18)
			
			var attrs = [NSAttributedString.Key : Any]()
			attrs[.font] = titleFont
			attrs[.foregroundColor] = UIColor.black
			attrs[.underlineStyle] = 1

			let titleParagraphStyle = NSMutableParagraphStyle()
			titleParagraphStyle.alignment = .center
			titleParagraphStyle.paragraphSpacing = 0.50 * titleFont.lineHeight
			attrs[.paragraphStyle] = titleParagraphStyle
			
			let printTitle = NSMutableAttributedString(string: title)
			let range = NSRange(location: 0, length: printTitle.length)
			printTitle.addAttributes(attrs, range: range)
			
			attrString.append(printTitle)
		}
	}
	
}

//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif
import UniformTypeIdentifiers
import OSLog
import CloudKit
import OrderedCollections
import VinUtility

public extension Notification.Name {
	static let OutlineTagsDidChange = Notification.Name(rawValue: "OutlineTagsDidChange")
	static let OutlineTextPreferencesDidChange = Notification.Name(rawValue: "OutlineTextPreferencesDidChange")
	static let OutlineElementsDidChange = Notification.Name(rawValue: "OutlineElementsDidChange")
	static let OutlineSearchWillBegin = Notification.Name(rawValue: "OutlineSearchWillBegin")
	static let OutlineSearchResultDidChange = Notification.Name(rawValue: "OutlineSearchResultDidChange")
	static let OutlineSearchWillEnd = Notification.Name(rawValue: "OutlineSearchWillEnd")
	static let OutlineSearchDidEnd = Notification.Name(rawValue: "OutlineSearchDidEnd")
	static let OutlineDidFocusOut = Notification.Name(rawValue: "OutlineDidFocusOut")
	static let OutlineAddedBacklinks = Notification.Name(rawValue: "OutlineAddedBacklinks")
	static let OutlineRemovedBacklinks = Notification.Name(rawValue: "OutlineRemovedBacklinks")
}

@MainActor
public final class Outline: RowContainer, Identifiable, Equatable, Hashable {
	
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
	
	public struct SearchOptions: OptionSet, Sendable {
		public static let wholeWords = SearchOptions(rawValue: 1)
		public static let caseInsensitive = SearchOptions(rawValue: 2)
		
		public let rawValue: Int
		public init(rawValue: Int) {
			self.rawValue = rawValue
		}
	}
	
	public enum SearchState {
		case beginSearch
		case searching
		case notSearching
	}
	
	public enum NumberingStyle: String, CustomStringConvertible, CaseIterable, Equatable, Codable {
		case none = "none"
		case simple = "simple"
		case decimal = "decimal"
		case legal = "legal"
		
		public var description: String {
			switch self {
			case .none:
				return "None"
			case .simple:
				return "Simple"
			case .decimal:
				return "Decimal"
			case .legal:
				return "Legal"
			}
		}
		
	}
	
	public struct UserInfoKeys {
		public static let replacableLinkTitle = "replacableLinkTitle"
		public static let searchText = "searchText"
	}
	
	public var outline: Outline? {
		return self
	}
	
	public private(set) var isSearching = SearchState.notSearching
	public private(set) var searchText = ""

	public private(set) var focusRow: Row? {
		get {
			if let focusRowID {
				return findRow(id: focusRowID)
			} else {
				return nil
			}
		}
		set {
			if let newValue {
				focusRowID = newValue.id
			} else {
				focusRowID = nil
			}
		}
	}
	
	public var adjustedRowsSection: Section {
		return isSearching == .notSearching ? Section.rows : Section.title
	}
		
	public var isBeingViewed: Bool {
		return beingViewedCount > 0
	}
	
	public var isOutlineCorrupted: Bool {
		guard let rowOrder, let keyedRows else { return false }
		
		var allRowOrderIDs = Set(keyedRows.values.flatMap({ $0.rowOrder }))
		allRowOrderIDs.formUnion(rowOrder)
		
		// If we have any extra rows that don't have an order, we have corruption
		for row in keyedRows.values {
			if !allRowOrderIDs.contains(row.id) {
				return true
			}
		}
		
		// If we have any rowOrder values that don't have keyedRows, we have corruption
		for rowID in rowOrder {
			if !keyedRows.keys.contains(rowID) {
				return true
			}
		}
		
		for row in keyedRows.values {
			for rowID in row.rowOrder {
				if !keyedRows.keys.contains(rowID) {
					return true
				}
			}
		}

		// Duplicate row IDs are a sign of curruption
		var seenRowIDs: Set<String> = []
		var foundCorruption = false
		
		func duplicateRowIDsVisitor(_ visited: Row) {
			for rowID in visited.rowOrder {
				if seenRowIDs.contains(rowID) {
					foundCorruption = true
					break
				} else {
					seenRowIDs.insert(rowID)
				}
			}
			visited.rows.forEach { $0.visit(visitor: duplicateRowIDsVisitor) }
		}

		for row in rows {
			row.visit(visitor: duplicateRowIDsVisitor)
		}

		return foundCorruption
	}
	
	public var cloudKitMetaData: Data? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var isCloudKitMerging: Bool = false

	nonisolated public let id: EntityID

	var ancestorTitle: String?
	var serverTitle: String?
	public internal(set) var title: String? {
		willSet {
			if isCloudKit && ancestorTitle == nil {
				ancestorTitle = title
			}
		}
	}
	
	var ancestorDisambiguator: Int?
	var serverDisambiguator: Int?
	public internal(set) var disambiguator: Int? {
		willSet {
			if isCloudKit && ancestorDisambiguator == nil {
				ancestorDisambiguator = disambiguator
			}
		}
	}
	
	var ancestorNumberingStyle: NumberingStyle?
	var serverNumberingStyle: NumberingStyle?
	public internal(set) var numberingStyle: NumberingStyle? {
		willSet {
			if isCloudKit && ancestorNumberingStyle == nil {
				ancestorNumberingStyle = numberingStyle
			}
		}
		didSet {
			if numberingStyle != oldValue {
				outlineTextPreferencesDidChange()
				documentMetaDataDidChange()
			}
		}
	}
	
	var ancestorAutomaticallyCreateLinks: Bool?
	var serverAutomaticallyCreateLinks: Bool?
	public internal(set) var automaticallyCreateLinks: Bool? {
		willSet {
			if isCloudKit && ancestorAutomaticallyCreateLinks == nil {
				ancestorAutomaticallyCreateLinks = automaticallyCreateLinks
			}
		}
		didSet {
			if automaticallyCreateLinks != oldValue {
				documentMetaDataDidChange()
			}
		}
	}
	
	var ancestorAutomaticallyChangeLinkTitles: Bool?
	var serverAutomaticallyChangeLinkTitles: Bool?
	public internal(set) var automaticallyChangeLinkTitles: Bool? {
		willSet {
			if isCloudKit && ancestorAutomaticallyChangeLinkTitles == nil {
				ancestorAutomaticallyChangeLinkTitles = automaticallyChangeLinkTitles
			}
		}
		didSet {
			if automaticallyChangeLinkTitles != oldValue {
				documentMetaDataDidChange()
			}
		}
	}
	
	var ancestorCheckSpellingWhileTyping: Bool?
	var serverCheckSpellingWhileTyping: Bool?
	public internal(set) var checkSpellingWhileTyping: Bool? {
		willSet {
			if isCloudKit && ancestorCheckSpellingWhileTyping == nil {
				ancestorCheckSpellingWhileTyping = checkSpellingWhileTyping
			}
		}
		didSet {
			if checkSpellingWhileTyping != oldValue {
				outlineTextPreferencesDidChange()
				documentMetaDataDidChange()
			}
		}
	}
	
	var ancestorCorrectSpellingAutomatically: Bool?
	var serverCorrectSpellingAutomatically: Bool?
	public internal(set) var correctSpellingAutomatically: Bool? {
		willSet {
			if isCloudKit && ancestorCorrectSpellingAutomatically == nil {
				ancestorCorrectSpellingAutomatically = correctSpellingAutomatically
			}
		}
		didSet {
			if correctSpellingAutomatically != oldValue {
				outlineTextPreferencesDidChange()
				documentMetaDataDidChange()
			}
		}
	}
	
	var ancestorOwnerName: String?
	var serverOwnerName: String?
	public internal(set) var ownerName: String? {
		willSet {
			if isCloudKit && ancestorOwnerName == nil {
				ancestorOwnerName = ownerName
			}
		}
	}
	
	var ancestorOwnerEmail: String?
	var serverOwnerEmail: String?
	public internal(set) var ownerEmail: String? {
		willSet {
			if isCloudKit && ancestorOwnerEmail == nil {
				ancestorOwnerEmail = ownerEmail
			}
		}
	}
	
	var ancestorOwnerURL: String?
	var serverOwnerURL: String?
	public internal(set) var ownerURL: String? {
		willSet {
			if isCloudKit && ancestorOwnerURL == nil {
				ancestorOwnerURL = ownerURL
			}
		}
	}

	var ancestorCreated: Date?
	var serverCreated: Date?
	public var created: Date? {
		willSet {
			if isCloudKit && ancestorCreated == nil {
				ancestorCreated = created
			}
		}
		didSet {
			if created != oldValue {
				documentMetaDataDidChange()
			}
		}
	}
	
	var ancestorUpdated: Date?
	var serverUpdated: Date?
	public var updated: Date? {
		willSet {
			if isCloudKit && ancestorUpdated == nil {
				ancestorUpdated = updated
			}
		}
		didSet {
			if updated != oldValue {
				documentUpdatedDidChange()
				documentMetaDataDidChange()
			}
		}
	}
	
	public var wordCount: Int {
		let wordCountVisitor = WordCountVisitor()

		load()
		
		rows.forEach { $0.visit(visitor: wordCountVisitor.visitor)	}
		
		Task {
			await unload()
		}

		return wordCountVisitor.count
	}
	
	public var verticleScrollState: Int? {
		didSet {
			documentMetaDataDidChange()
		}
	}

	public var isFilterOn: Bool? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var isCompletedFilterOn: Bool {
		return isFilterOn ?? false && isCompletedFiltered ?? true
	}

	public var isCompletedFiltered: Bool? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	public var isNotesFilterOn: Bool {
		return isFilterOn ?? false && isNotesFiltered ?? true
	}

	public var isNotesFiltered: Bool? {
		didSet {
			documentMetaDataDidChange()
		}
	}
	
	var ancestorDocumentLinks: [EntityID]?
	var serverDocumentLinks: [EntityID]?
	public internal(set) var documentLinks: [EntityID]?
	
	var ancestorDocumentBacklinks: [EntityID]?
	var serverDocumentBacklinks: [EntityID]?
	public internal(set) var documentBacklinks: [EntityID]?
	
	var ancestorHasAltLinks: Bool?
	var serverHasAltLinks: Bool?
	public internal(set) var hasAltLinks: Bool? {
		willSet {
			if isCloudKit && ancestorHasAltLinks == nil {
				ancestorHasAltLinks = hasAltLinks
			}
		}
		didSet {
			if hasAltLinks != oldValue {
				documentMetaDataDidChange()
			}
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
			if cloudKitShareRecordName == nil {
				cloudKitShareRecordData = nil
			}
			if cloudKitShareRecordName != oldValue {
				documentSharingDidChange()
				documentMetaDataDidChange()
			}
		}
	}
	
	public var cloudKitShareRecordData: Data? {
		didSet {
			if cloudKitShareRecordData != oldValue {
				documentSharingDidChange()
				documentMetaDataDidChange()
			}
		}
	}

	public var rows: [Row] {
		get {
			if let rowOrder, let rowData = keyedRows {
				return rowOrder.compactMap { rowData[$0] }
			} else {
				return [Row]()
			}
		}
	}
	
	public var allRows: [Row] {
		get {
			var all = [Row]()

			func allRowVisitor(_ visited: Row) {
				all.append(visited)
				visited.rows.forEach { $0.visit(visitor: allRowVisitor) }
			}

			rows.forEach { $0.visit(visitor: allRowVisitor(_:)) }

			return all
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
	
	public var iCollaborating: Bool {
		return cloudKitShareRecord != nil
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
	
	public private(set) weak var account: Account?
	
	public var tags: [Tag] {
		guard let account else { return [Tag]() }
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
				.compactMap({ String($0).trimmed() })
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
				  let isInNotes = selectionIsInNotes,
				  let location = selectionLocation,
				  let length = selectionLength else {
				return nil
			}
			return CursorCoordinates(rowID: rowID.rowUUID, isInNotes: isInNotes, selection: NSRange(location: location, length: length))
		}
		set {
			if let coordinates = newValue {
				selectionRowID = .row(id.accountID, id.documentUUID, coordinates.rowID)
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
		
		if let keyedRows {
			for row in keyedRows.values {
				if row.isComplete ?? false {
					anyCompleted = true
					break
				}
			}
		}
		
		return anyCompleted
	}
	
	public var allCompletedRows: [Row] {
		var completedRows = [Row]()
		
		if let shadowTable {
			for row in shadowTable {
				if row.isComplete ?? false {
					completedRows.append(row)
				}
			}
		}

		return completedRows
	}
	
    public var images: [String: [Image]]? {
        didSet {
            if let images {
                for imageArray in images.values {
                    for image in imageArray {
                        image.outline = self
                    }
                }
            }
        }
    }
	
	public private(set) var currentSearchResult = -1
	public private(set) var searchResultCoordinates = [SearchResultCoordinates]()
	
	public var currentSearchResultRow: Row? {
		guard currentSearchResult > -1 && currentSearchResult < searchResultCoordinates.count else { return nil }
		return searchResultCoordinates[currentSearchResult].row
	}
	
	public var searchResultCount: Int {
		return searchResultCoordinates.count
	}
	
	public var isCurrentSearchResultReplacable: Bool {
		guard currentSearchResult >= 0 else { return false }
		return searchResultCoordinates[currentSearchResult].range.length != 0
	}
	
	var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinOutlineKit")

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
			guard let recordName = cloudKitShareRecordName, let zoneID else { return nil }
			return CKRecord.ID(recordName: recordName, zoneID: zoneID)
		}
		set {
			cloudKitShareRecordName = newValue?.recordName
			zoneID = newValue?.zoneID
		}
	}
	
	var ancestorRowOrder: OrderedSet<String>?
	var serverRowOrder: OrderedSet<String>?
	var rowOrder: OrderedSet<String>?
	var keyedRows: [String: Row]? {
		didSet {
			if let keyedRows {
				for row in keyedRows.values {
					row.outline = self
				}
			}
		}
	}
	
	var ancestorTagIDs: [String]?
	var serverTagIDs: [String]?
	var tagIDs: [String]?
	
	var rowsFile: RowsFile?
	var imagesFile: ImagesFile?
	
	var batchCloudKitRequests = 0
	var cloudKitRequestsIDs = Set<EntityID>()
	
	private var beingViewedCount = 0
	private var beingUsedCount = 0

	private var focusRowID: String?
	private var selectionRowID: EntityID?
	private var selectionIsInNotes: Bool?
	private var selectionLocation: Int?
	private var selectionLength: Int?

	init(account: Account?, id: EntityID) {
		self.account = account
		self.id = id
		self.created = Date()
		self.updated = Date()
		rowsFile = RowsFile(outline: self)
		imagesFile = ImagesFile(outline: self)
		beingUsedCount = 1
	}

	init(account: Account?, parentID: EntityID, title: String?) {
		self.account = account
		self.id = .document(parentID.accountID, UUID().uuidString)
		self.title = title
		self.created = Date()
		self.updated = Date()
		rowsFile = RowsFile(outline: self)
		imagesFile = ImagesFile(outline: self)
		beingUsedCount = 1
	}
	
	init(account: Account?, coder: OutlineCoder) {
		self.account = account
		self.cloudKitMetaData = coder.cloudKitMetaData
		self.id = coder.id
		self.ancestorTitle = coder.ancestorTitle
		self.title = coder.title
		self.ancestorDisambiguator = coder.ancestorDisambiguator
		self.disambiguator = coder.disambiguator
		self.ancestorCreated = coder.ancestorCreated
		self.created = coder.created
		self.ancestorUpdated = coder.ancestorUpdated
		self.updated = coder.updated
		self.ancestorAutomaticallyCreateLinks = coder.ancestorAutomaticallyCreateLinks
		self.numberingStyle = coder.numberingStyle
		self.ancestorNumberingStyle = coder.ancestorNumberingStyle
		self.automaticallyCreateLinks = coder.automaticallyCreateLinks
		self.ancestorAutomaticallyChangeLinkTitles = coder.ancestorAutomaticallyChangeLinkTitles
		self.automaticallyChangeLinkTitles = coder.automaticallyChangeLinkTitles
		self.ancestorCheckSpellingWhileTyping = coder.ancestorCheckSpellingWhileTyping
		self.checkSpellingWhileTyping = coder.checkSpellingWhileTyping
		self.ancestorCorrectSpellingAutomatically = coder.ancestorCorrectSpellingAutomatically
		self.correctSpellingAutomatically = coder.correctSpellingAutomatically
		self.ancestorOwnerName = coder.ancestorOwnerName
		self.ownerName = coder.ownerName
		self.ancestorOwnerEmail = coder.ancestorOwnerEmail
		self.ownerEmail = coder.ownerEmail
		self.ancestorOwnerURL = coder.ancestorOwnerURL
		self.ownerURL = coder.ownerURL
		self.verticleScrollState = coder.verticleScrollState
		self.isFilterOn = coder.isFilterOn
		self.isCompletedFiltered = coder.isCompletedFiltered
		self.isNotesFiltered = coder.isNotesFiltered
		self.focusRowID = coder.focusRowID
		self.selectionRowID = coder.selectionRowID
		self.selectionIsInNotes = coder.selectionIsInNotes
		self.selectionLocation = coder.selectionLocation
		self.selectionLength = coder.selectionLength
		self.ancestorTagIDs = coder.ancestorTagIDs
		self.tagIDs = coder.tagIDs
		self.ancestorDocumentLinks = coder.ancestorDocumentLinks
		self.documentLinks = coder.documentLinks
		self.ancestorDocumentBacklinks = coder.ancestorDocumentBacklinks
		self.documentBacklinks = coder.documentBacklinks
		self.ancestorHasAltLinks = coder.ancestorHasAltLinks
		self.hasAltLinks = coder.hasAltLinks
		self.cloudKitZoneName = coder.cloudKitZoneName
		self.cloudKitZoneOwner = coder.cloudKitZoneOwner
		self.cloudKitShareRecordName = coder.cloudKitShareRecordName
		self.cloudKitShareRecordData = coder.cloudKitShareRecordData
	}
	
	public func incrementBeingViewedCount() {
		beingViewedCount = beingViewedCount + 1
	}

	public func decrementBeingViewedCount() {
		beingViewedCount = beingViewedCount - 1
	}

	public func prepareForViewing() {
		rebuildTransientData()
	}
	
	public func rowsFileDidLoad() {
		// We need to make sure that there is still an account. This can be set to nil when
		// reloading the Account File and something is holding on to an Outline still. Most
		// likely this is the Editor while the Outline is being viewed.
		guard isBeingViewed, account != nil else { return }
		
		var changes = rebuildShadowTable()
		let reloads = Set(shadowTable!.compactMap { $0.shadowTableIndex })
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		
		outlineElementsDidChange(changes)
	}
	
	public func correctRowToRowOrderCorruption() {
		guard let rowOrder, let keyedRows else { return }
		
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
		var allRowOrderIDs = Set(keyedRows.values.flatMap({ $0.rowOrder }))
		allRowOrderIDs.formUnion(rowOrder)
		
		var foundCorruption = false

		// Fix any rowOrder values that don't have keyedRows. Sync the RowContainer with the bad
		// rowOrder as well as any missing rows that it had referenced. Another device might still
		// have that row causing a back and forth between devices about which rowOrder is correct or not.
		//
		// Do not request CloudKit updates for any rows removed from the the rowOrder tables. They may actually
		// have just not synced to the current device yet and we don't want to remove them from iCloud if so.
		for rowID in rowOrder {
			if !keyedRows.keys.contains(rowID) {
				self.rowOrder?.remove(rowID)
				foundCorruption = true
			}
		}
		
		for row in keyedRows.values {
			for rowID in row.rowOrder {
				if !keyedRows.keys.contains(rowID) {
					row.rowOrder.remove(rowID)
					foundCorruption = true
				}
			}
		}

		// Fix any keyRows that don't have rowOrder entries
		for row in keyedRows.values {
			if !allRowOrderIDs.contains(row.id) {
				self.rowOrder?.append(row.id)
				requestCloudKitUpdates(for: [self.id, row.entityID])
				foundCorruption = true
			}
		}
	
		if foundCorruption {
			outlineContentDidChange()
			outlineElementsDidChange(rebuildShadowTable())
		}
	}
	
	public func correctDuplicateRowCorruption() {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
		var foundCorruption = false
		
		// Remove duplicate row order entries. It is possible that a user may have moved a row to a new parent
		// on a disconnected device and to a different parent on a connected device. Our merge won't detect this
		// since it is working on a per record basis and a row could end up owned by multiple rows.
		var seenRowIDs: Set<String> = []

		func duplicateRowIDsVisitor(_ visited: Row) {
			for rowID in visited.rowOrder {
				if seenRowIDs.contains(rowID) {
					visited.rowOrder.remove(rowID)
					requestCloudKitUpdate(for: self.id)
					foundCorruption = true
				} else {
					seenRowIDs.insert(rowID)
				}
			}
			visited.rows.forEach { $0.visit(visitor: duplicateRowIDsVisitor) }
		}
		
		for row in rows {
			row.visit(visitor: duplicateRowIDsVisitor)
		}

		// Row order corruption happens when merging the row orders during an iCloud sync. When an indent may have
		// happened on a connected device to a row that was deleted on an unconnected device, an insert will happen
		// into a row order array for the unconnected device once it is connected again and syncs.
		if foundCorruption {
			outlineContentDidChange()
			outlineElementsDidChange(rebuildShadowTable())
		}
	}
	
	public func findRowContainer(entityID: EntityID) -> RowContainer? {
		guard id != entityID else {
			return self
		}
		if case .row(_, _, let rowUUID) = entityID {
			return findRow(id: rowUUID)
		}
		return nil
	}
	
	public func findRow(id: String) -> Row? {
		return keyedRows?[id]
	}
	
	public func firstIndexOfRow(_ row: Row) -> Int? {
		return rowOrder?.firstIndex(of: row.id)
	}

	public func containsRow(_ row: Row) -> Bool {
		return rowOrder?.contains(row.id) ?? false
	}

	public func insertRow(_ row: Row, at: Int) {
		if isCloudKit && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}

		if rowOrder == nil {
			rowOrder = OrderedSet<String>()
		}

		if keyedRows == nil {
			keyedRows = [String: Row]()
		}

		rowOrder?.insert(row.id, at: at)
		keyedRows?[row.id] = row

		requestCloudKitUpdates(for: [id, row.entityID])
	}

	public func removeRow(_ row: Row) {
		if isCloudKit && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}

		rowOrder?.remove(row.id)
		keyedRows?.removeValue(forKey: row.id)
		
		requestCloudKitUpdates(for: [id, row.entityID])
	}

	public func appendRow(_ row: Row) {
		if isCloudKit && ancestorRowOrder == nil {
			ancestorRowOrder = rowOrder
		}

		if rowOrder == nil {
			rowOrder = OrderedSet<String>()
		}
		
		if keyedRows == nil {
			keyedRows = [String: Row]()
		}
		
		rowOrder?.append(row.id)
		keyedRows?[row.id] = row

		requestCloudKitUpdates(for: [id, row.entityID])
	}
	
	public func createTag(_ tag: Tag) {
		guard !hasTag(tag) else { return }
		
		if isCloudKit && ancestorTagIDs == nil {
			ancestorTagIDs = tagIDs
		}

		if tagIDs == nil {
			tagIDs = [String]()
		}
		tagIDs!.append(tag.id)
		self.updated = Date()
		
		outlineTagsDidChange()
		requestCloudKitUpdate(for: id)

		guard isBeingViewed else { return }
		
		let inserted = tagIDs!.count
		let reload = inserted - 1
		var changes = OutlineElementChanges(section: .tags, inserts: Set([inserted]), reloads: Set([reload]))
		changes.isReloadsAnimatable = true
		outlineElementsDidChange(changes)
	}
	
	public func deleteTag(_ tag: Tag) {
		guard let index = tagIDs?.firstIndex(where: { $0 == tag.id }) else { return }
		
		if isCloudKit && ancestorTagIDs == nil {
			ancestorTagIDs = tagIDs
		}

		tagIDs?.remove(at: index)
		self.updated = Date()

		outlineTagsDidChange()
		requestCloudKitUpdate(for: id)

		guard isBeingViewed else { return }

		let reload = tagIDs?.count ?? 1
		var changes = OutlineElementChanges(section: .tags, deletes: Set([index]), reloads: Set([reload]))
		changes.isReloadsAnimatable = true
		outlineElementsDidChange(changes)
	}
	
    public func hasAnyTag(_ tags: [Tag]) -> Bool {
        guard let tagIDs else { return false }
        for tag in tags {
            if tagIDs.contains(tag.id) {
                return true
            }
        }
        return false
    }
    
	public func hasTag(_ tag: Tag) -> Bool {
		guard let tagIDs else { return false }
		return tagIDs.contains(tag.id)
	}
	
	public func filename(type: UTType) -> String {
		var filename = title ?? "Outline"
		
		filename = filename
			.replacingOccurrences(of: " ", with: "_")
			.replacingOccurrences(of: "/", with: "-")
			.trimmingCharacters(in: .whitespaces)
		
		if let disambiguator {
			filename = "\(filename)-\(disambiguator)"
		}
		
		filename = "\(filename).\(type.preferredFilenameExtension!)"
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

		Task {
			await unload()
		}
		
		return print
	}
	
	public func printList() -> NSAttributedString {
		let print = NSMutableAttributedString()
		load()
		
		appendPrintTitle(attrString: print)
		
		rows.forEach {
			let visitor = PrintListVisitor(numberingStyle: numberingStyle ?? .none)
			$0.visit(visitor: visitor.visitor)
			print.append(visitor.print)
		}

		Task {
			await unload()
		}
		
		return print
	}
	
	public func textContent() -> String {
		load(includeImages: false)
		
		var textContent = "\(title ?? "")\n\n"
		rows.forEach {
			let visitor = StringVisitor()
			$0.visit(visitor: visitor.visitor)
			textContent.append(visitor.string)
			textContent.append("\n")
		}
		
		Task {
			await unload()
		}
		
		return textContent
	}
	
	public func markdownDoc(useAltLinks: Bool = false) -> String {
		load()
		
		var md = "# \(title ?? "")"
		let visitor = MarkdownDocVisitor(useAltLinks: useAltLinks)
		rows.forEach {
			$0.visit(visitor: visitor.visitor)
		}
		md.append(visitor.markdown)

		Task {
			await unload()
		}
		
		return md
	}
	
	public func markdownList(useAltLinks: Bool = false) -> String {
		load()
		
		var md = "# \(title ?? "")\n\n"
		rows.forEach {
			let visitor = MarkdownListVisitor(useAltLinks: useAltLinks, numberingStyle: numberingStyle ?? .none)
			$0.visit(visitor: visitor.visitor)
			md.append(visitor.markdown)
			md.append("\n")
		}
		
		Task {
			await unload()
		}
		
		return md
	}
	
	public func opml(indentLevel: Int = 0, useAltLinks: Bool = false) -> String {
		load()

		var opml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		opml.append("<!-- OPML generated by Zavala -->\n")
		opml.append("<opml version=\"2.0\">\n")
		opml.append("<head>\n")
		
		opml.append("  <title>\(title?.escapingXMLCharacters ?? "")</title>\n")
		
		if let dateCreated = created?.rfc822String {
			opml.append("  <dateCreated>\(dateCreated)</dateCreated>\n")
		}
		if let dateModified = updated?.rfc822String {
			opml.append("  <dateModified>\(dateModified)</dateModified>\n")
		}
		
		if let ownerName {
			opml.append("  <ownerName>\(ownerName.escapingXMLCharacters)</ownerName>\n")
		}
		if let ownerEmail {
			opml.append("  <ownerEmail>\(ownerEmail.escapingXMLCharacters)</ownerEmail>\n")
		}
		if let ownerURL {
			opml.append("  <ownerID>\(ownerURL.escapingXMLCharacters)</ownerID>\n")
		}
		
		opml.append("  <expansionState>\(expansionState)</expansionState>\n")
		
		if let verticleScrollState {
			opml.append("  <vertScrollState>\(verticleScrollState)</vertScrollState>\n")
		}
		
		if let numberingStyle {
			opml.append("  <numberingStyle>\(numberingStyle.rawValue)</numberingStyle>\n")
		}

		if let automaticallyCreateLinks {
			opml.append("  <automaticallyCreateLinks>\(automaticallyCreateLinks ? "true" : "false")</automaticallyCreateLinks>\n")
		}

		if let automaticallyChangeLinkTitles {
			opml.append("  <automaticallyChangeLinkTitles>\(automaticallyChangeLinkTitles ? "true" : "false")</automaticallyChangeLinkTitles>\n")
		}

		if let checkSpellingWhileTyping {
			opml.append("  <checkSpellingWhileTyping>\(checkSpellingWhileTyping ? "true" : "false")</checkSpellingWhileTyping>\n")
		}
		
		if let correctSpellingAutomatically {
			opml.append("  <correctSpellingAutomatically>\(correctSpellingAutomatically ? "true" : "false")</correctSpellingAutomatically>\n")
		}

		if !(tagIDs?.isEmpty ?? true) {
			opml.append("  <tags>\n")
			for tag in tags {
				opml.append("    <tag>\(tag.name.escapingXMLCharacters)</tag>\n")
			}
			opml.append("  </tags>\n")
		}
		
		opml.append("</head>\n")
		opml.append("<body>\n")
		rows.forEach {
			let visitor = OPMLVisitor(useAltLinks: useAltLinks)
			$0.visit(visitor: visitor.visitor)
			opml.append(visitor.opml)
		}
		opml.append("</body>\n")
		opml.append("</opml>\n")

		Task {
			await unload()
		}
		
		return opml
	}
	
	public func update(title: String?) {
		self.title = title
		updated = Date()
		documentTitleDidChange()
		requestCloudKitUpdate(for: id)
	}
	
	public func update(disambiguator: Int) {
		self.disambiguator = disambiguator
		requestCloudKitUpdate(for: id)
	}
	
	public func update(ownerName: String?) {
		self.ownerName = ownerName
		updated = Date()
		requestCloudKitUpdate(for: id)
	}
	
	public func update(ownerEmail: String?) {
		self.ownerEmail = ownerEmail
		updated = Date()
		requestCloudKitUpdate(for: id)
	}
	
	public func update(ownerURL: String?) {
		self.ownerURL = ownerURL
		updated = Date()
		requestCloudKitUpdate(for: id)
	}
	
	public func update(numberingStyle: NumberingStyle,
					   checkSpellingWhileTyping: Bool,
					   correctSpellingAutomatically: Bool,
					   automaticallyCreateLinks: Bool,
					   automaticallyChangeLinkTitles: Bool,
					   ownerName: String?,
					   ownerEmail: String?,
					   ownerURL: String?) {
		
		self.numberingStyle = numberingStyle
		self.checkSpellingWhileTyping = checkSpellingWhileTyping
		self.correctSpellingAutomatically = correctSpellingAutomatically
		
		self.automaticallyCreateLinks = automaticallyCreateLinks
		self.automaticallyChangeLinkTitles = automaticallyChangeLinkTitles
		self.ownerName = ownerName
		self.ownerEmail = ownerEmail
		self.ownerURL = ownerURL
		
		updated = Date()
		requestCloudKitUpdate(for: id)
	}
	
	public func shouldMoveLeftOnReturn(row: Row) -> Bool {
		guard row.topic == nil else { return false }
		
		guard row.parent is Row else { return false }
		
		if row.parent?.rows.last == row {
			return true
		} else {
			return false
		}
	}
	
	func deleteAllBacklinks() {
		guard let documentBacklinks else { return }
		
		for documentBacklink in documentBacklinks {
			deleteBacklink(documentBacklink)
		}
	}
	
	public func toggleFilterOn() -> OutlineElementChanges {
		isFilterOn = !(isFilterOn ?? false)
		documentMetaDataDidChange()
		var changes = rebuildShadowTable()

		if let reloads = shadowTable?.filter({ !$0.isNoteEmpty }).compactMap({ $0.shadowTableIndex }) {
			changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads)))
			changes.isReloadsAnimatable = true
		}
		
		return changes
	}
	
	public func toggleCompletedFilter() -> OutlineElementChanges {
		isCompletedFiltered = !(isCompletedFiltered ?? true)
		documentMetaDataDidChange()
		return rebuildShadowTable()
	}
	
	public func toggleNotesFilter() -> OutlineElementChanges {
		isNotesFiltered = !(isNotesFiltered ?? true)
		documentMetaDataDidChange()
		
		if let reloads = shadowTable?.filter({ !$0.isNoteEmpty }).compactMap({ $0.shadowTableIndex }) {
			var changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
			changes.isReloadsAnimatable = true
			return changes
		} else {
			return OutlineElementChanges(section: adjustedRowsSection)
		}
	}
	
	public func isCreateNotesUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if row.isNoteEmpty {
				return false
			}
		}
		return true
	}
	
	public func search(for searchText: String, options: SearchOptions) {
		if isSearching == .notSearching {
			isSearching = .beginSearch
			outlineSearchWillBegin()
		}

		guard self.searchText != searchText else {
			return
		}

		self.searchText = searchText

		clearSearchResults()

		if searchText.isEmpty {
			isSearching = .beginSearch
		} else {
			isSearching = .searching
			let searchVisitor = SearchResultVisitor(searchText: searchText, options: options, isCompletedFilterOn: isCompletedFilterOn, isNotesFilterOn: isNotesFilterOn)
			rows.forEach { $0.visit(visitor: searchVisitor.visitor(_:))	}
			searchResultCoordinates = searchVisitor.searchResultCoordinates
		}
				
		var changes = rebuildShadowTable()
		let reloads = searchResultCoordinates.compactMap { $0.row.shadowTableIndex }
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads)))
		outlineElementsDidChange(changes)
	}
	
	public func restartSearch() {
		guard isSearching == .searching else { return }
		
		searchText = ""
		isSearching = .beginSearch
		clearSearchResults()
		outlineElementsDidChange(rebuildShadowTable())
		
		isSearching = .searching
	}
	
	public func replaceSearchResults(_ coordinates: [SearchResultCoordinates], with replacement: String) {
		var reloads = Set<Int>()
		
		for coordinate in coordinates {
			guard coordinate.range.length != 0 else { continue }
			
			if coordinate.isInNotes {
				guard let attrString = coordinate.row.note else { continue }
				let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
				mutableAttrString.replaceCharacters(in: coordinate.range, with: replacement)
				coordinate.row.note = mutableAttrString
			} else {
				guard let attrString = coordinate.row.topic else { continue }
				let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
				mutableAttrString.replaceCharacters(in: coordinate.range, with: replacement)
				coordinate.row.topic = mutableAttrString
			}
			
			coordinate.range.length = 0

			if let reload = coordinate.row.shadowTableIndex {
				reloads.insert(reload)
			}
		}
		
		outlineElementsDidChange(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
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
		outlineSearchWillEnd()
		isSearching = .notSearching
		searchText = ""

		guard isBeingViewed else { return }
		
		var changes = rebuildShadowTable()

		// Reload any rows that should be collapsed so that thier disclosure is in the correct position
		if let reloads = shadowTable?.filter({ !$0.isExpanded }).compactMap({ $0.shadowTableIndex }) {
			changes.append(OutlineElementChanges(section: .rows, reloads: Set(reloads)))
		}
		
		outlineElementsDidChange(changes)
		outlineSearchDidEnd()
	}
	
	public func focusIn(_ row: Row) {
		self.focusRow = row
		
		var changes = rebuildShadowTable()

		var reloads = Set<Int>()
		func reloadVisitor(_ visited: Row) {
			if let index = visited.shadowTableIndex {
				reloads.insert(index)
			}
			if visited.isExpanded {
				visited.rows.forEach { $0.visit(visitor: reloadVisitor) }
			}
		}
		reloadVisitor(row)

		changes.append(OutlineElementChanges(section: .rows, reloads: reloads))
		outlineElementsDidChange(changes)
	}

	public func isFocusOutUnavailable() -> Bool {
		return focusRow == nil
	}
	
	public func focusOut() {
		guard let reloadRow = self.focusRow else { return }
		
		self.focusRow = nil
		var changes = rebuildShadowTable()
		
		var reloads = Set<Int>()
		func reloadVisitor(_ visited: Row) {
			if let index = visited.shadowTableIndex {
				reloads.insert(index)
			}
			if visited.isExpanded {
				visited.rows.forEach { $0.visit(visitor: reloadVisitor) }
			}
		}
		reloadVisitor(reloadRow)
		changes.append(OutlineElementChanges(section: .rows, reloads: Set(reloads)))
		
		outlineElementsDidChange(changes)
		outlineDidFocusOut()
	}

	func findImages(rowID: String) -> [Image]? {
		return images?[rowID]
	}
	
	func updateImages(rowID: String, images: [Image]?) {
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
	
	func removeImages(rowID: String) {
		self.images?.removeValue(forKey: rowID)
		imagesFile?.markAsDirty()
	}
	
	func createNotes(rows: [Row], rowStrings: RowStrings?) -> [Row] {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
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
		
		outlineContentDidChange()
		
		guard isBeingViewed else {
			return impacted
		}
		
		let reloads = impacted.compactMap { $0.shadowTableIndex }
		var changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
		changes.isReloadsAnimatable = true
		changes.cursorMoveIsToNote = true
		changes.newCursorIndex = reloads.sorted().first
		outlineElementsDidChange(changes)
		
		return impacted
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
	public func deleteNotes(rows: [Row], rowStrings: RowStrings? = nil) -> [Row: NSAttributedString] {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
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

		outlineContentDidChange()

		guard isBeingViewed else {
			return impacted
		}

		let reloads = impacted.keys.compactMap { $0.shadowTableIndex }
		var changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
		changes.isReloadsAnimatable = true
		changes.cursorMoveIsBeforeChanges = true
		changes.newCursorIndex = reloads.sorted().first
		outlineElementsDidChange(changes)
		
		return impacted
	}
	
	func restoreNotes(_ notes: [Row: NSAttributedString]) {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
		for (row, note) in notes {
			row.note = note
		}

		outlineContentDidChange()
		
		guard isBeingViewed else { return }
		
		let reloads = notes.keys.compactMap { $0.shadowTableIndex }
		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads))
		outlineElementsDidChange(changes)
		
	}
	
	public func deleteRows(_ rows: [Row], rowStrings: RowStrings? = nil, isInOutlineMode: Bool = false) {
		collapseAllInOutlineUnavailableNeedsUpdate = true
		
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}

		var parentReloads = Set<Int>()

		func deleteVisitor(_ visited: Row) {
			removeImages(rowID: visited.id)
			visited.rows.forEach { $0.visit(visitor: deleteVisitor) }
		}
		
		for row in rows {
			row.parent?.removeRow(row)
			removeImages(rowID: row.id)
			row.visit(visitor: deleteVisitor(_:))
			
			if let parentRow = row.parent as? Row, autoCompleteUncomplete(row: parentRow) {
				if let parentRowIndex = parentRow.shadowTableIndex {
					parentReloads.insert(parentRowIndex)
				}
			}
		}

		deleteLinkRelationships(for: rows)
		outlineContentDidChange()
		
		guard isBeingViewed else { return }
		
		var changes = rebuildShadowTable()
		
		var reloads = rows.compactMap { ($0.parent as? Row)?.shadowTableIndex }
		reloads.append(contentsOf: parentReloads)

		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: Set(reloads)))
		
		if isInOutlineMode {
			if let firstDelete = rows.first?.shadowTableIndex, firstDelete >= 0 {
				let shadowTableCount = shadowTable?.count ?? 0
				if firstDelete < shadowTableCount {
					changes.newSelectIndex = firstDelete
				} else if shadowTableCount > 0 {
					changes.newSelectIndex = shadowTableCount - 1
				}
			}
		} else {
			changes.cursorMoveIsBeforeChanges = true
			if rows.contains(where: { $0.id == selectionRowID?.rowUUID }) {
				if let firstDelete = rows.first?.shadowTableIndex, firstDelete > 0 {
					changes.newCursorIndex = firstDelete - 1
				} else {
					changes.newCursorIndex = -1
				}
			}
		}

		outlineElementsDidChange(changes)
		
	}
	
	func joinRows(topRow: Row, bottomRow: Row, topic: NSAttributedString? = nil) {
		// If we Join a Row with children we need to transfer the child Rows or they will
		// be orphaned. For now, I've opted to just not allow this action.
		guard bottomRow.rowCount == 0 else { return }
		
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
		requestCloudKitUpdate(for: topRow.entityID)
		updateRowStrings(topRow, .topic(topic))
		deleteRows([bottomRow])
		
		guard isBeingViewed, let topShadowTableIndex = topRow.shadowTableIndex else { return }

		let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: Set([topShadowTableIndex]))
		outlineElementsDidChange(changes)
	}
	
	public func isGroupRowsUnavailable(rows: [Row]) -> Bool {
		return !areRowsContiguous(rows: rows)
	}
	
	public func isSortRowsUnavailable(rows: [Row]) -> Bool {
		guard rows.count > 1 else { return true }
		return !areRowsContiguous(rows: rows)
	}
	
	func areRowsContiguous(rows: [Row]) -> Bool {
		let sortedRows = rows.sortedByDisplayOrder()
		
		guard let firstRow = sortedRows.first,
			  let parent = firstRow.parent,
			  let firstIndex = parent.firstIndexOfRow(firstRow) else {
			return false
		}
		
		for i in 0..<sortedRows.count {
			let row = sortedRows[i]
			guard let index = parent.firstIndexOfRow(row) else {
				return false
			}

			if index == firstIndex + i {
				continue
			} else {
				return false
			}
		}
		
		return true
	}
	
	func createRow(_ row: Row, beforeRow: Row, rowStrings: RowStrings? = nil, moveCursor: Bool) {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
		if let texts = rowStrings {
			updateRowStrings(beforeRow, texts)
		}

		resetPreviouslyUsed(rows: [row])
		
		guard let parent = beforeRow.parent,
			  let index = parent.firstIndexOfRow(beforeRow),
			  let shadowTableIndex = beforeRow.shadowTableIndex else {
			return
		}
		
		parent.insertRow(row, at: index)
		row.parent = parent
		
		var reloads = Set<Int>()
		
		if let parentRow = parent as? Row, autoCompleteUncomplete(row: parentRow) {
			if let parentRowIndex = parentRow.shadowTableIndex {
				reloads.insert(parentRowIndex)
			}
		}
		
		createLinkRelationships(for: [row])
		replaceLinkTitlesIfPossible(rows: [row])
		outlineContentDidChange()

		guard isBeingViewed else { return }

		var changes = rebuildShadowTable()
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		
		if moveCursor {
			changes.newCursorIndex = shadowTableIndex
		}
		
		outlineElementsDidChange(changes)
	}
	
	@discardableResult
	func createRow(_ row: Row, parent: RowContainer? = nil, index: Int? = nil, afterRow: Row? = nil, rowStrings: RowStrings? = nil) -> Int? {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
		if let afterRow, let texts = rowStrings {
			updateRowStrings(afterRow, texts)
		}
		
		resetPreviouslyUsed(rows: [row])
		
		if let parent, let index {
			parent.insertRow(row, at: index)
		} else if afterRow == nil {
			insertRow(row, at: 0)
			row.parent = self
		} else if afterRow == focusRow {
			afterRow?.insertRow(row, at: 0)
			row.parent = afterRow
		} else if afterRow?.isExpanded ?? true && !(afterRow?.rowCount == 0) {
			afterRow?.insertRow(row, at: 0)
			row.parent = afterRow
		} else if let afterRow, let parent = afterRow.parent {
			let insertIndex = parent.firstIndexOfRow(afterRow) ?? -1
			parent.insertRow(row, at: insertIndex + 1)
			row.parent = afterRow.parent
		} else if let afterRow {
			let insertIndex = firstIndexOfRow(afterRow) ?? -1
			insertRow(row, at: insertIndex + 1)
			row.parent = self
		} else {
			insertRow(row, at: 0)
			row.parent = self
		}

		var reloads = Set<Int>()

		if let parentRow = row.parent as? Row, autoCompleteUncomplete(row: parentRow) {
			if let parentRowIndex = parentRow.shadowTableIndex {
				reloads.insert(parentRowIndex)
			}
		}
		
		createLinkRelationships(for: [row])
		replaceLinkTitlesIfPossible(rows: [row])
		outlineContentDidChange()
			
		guard isBeingViewed else { return nil }

		if let reload = afterRow?.shadowTableIndex {
			reloads.insert(reload)
		}

		var changes = rebuildShadowTable()
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		
		changes.newCursorIndex = row.shadowTableIndex
		outlineElementsDidChange(changes)
		
		return row.shadowTableIndex
	}

	func createRows(_ rows: [Row], afterRow: Row? = nil, rowStrings: RowStrings? = nil, prefersEnd: Bool = false) {
		collapseAllInOutlineUnavailableNeedsUpdate = true
		
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
		if let afterRow, let texts = rowStrings {
			updateRowStrings(afterRow, texts)
		}
		
		resetPreviouslyUsed(rows: rows)
		
		var reloads = Set<Int>()
		let beginningRowCount = rowCount

		for row in rows.sortedByReverseDisplayOrder() {
			if afterRow == nil {
				if prefersEnd {
					insertRow(row, at: beginningRowCount)
				} else {
					insertRow(row, at: 0)
				}
				row.parent = self
			} else if let parent = row.parent, parent as? Row == afterRow {
				parent.insertRow(row, at: 0)
			} else if let parent = row.parent, let afterRow {
				let insertIndex = parent.firstIndexOfRow(afterRow) ?? parent.rowCount - 1
				parent.insertRow(row, at: insertIndex + 1)
			} else if afterRow == focusRow {
				afterRow?.insertRow(row, at: 0)
				row.parent = afterRow
			} else if afterRow?.isExpanded ?? true && !(afterRow?.rowCount == 0) {
				afterRow?.insertRow(row, at: 0)
				row.parent = afterRow
			} else if let afterRow, let parent = afterRow.parent {
				let insertIndex = parent.firstIndexOfRow(afterRow) ?? -1
				parent.insertRow(row, at: insertIndex + 1)
				row.parent = afterRow.parent
			} else if let afterRow {
				let insertIndex = firstIndexOfRow(afterRow) ?? -1
				insertRow(row, at: insertIndex + 1)
				row.parent = self
			} else {
				insertRow(row, at: 0)
				row.parent = self
			}
			
			if let parentRow = row.parent as? Row, autoCompleteUncomplete(row: parentRow) {
				if let parentRowIndex = parentRow.shadowTableIndex {
					reloads.insert(parentRowIndex)
				}
			}
		}
		
		createLinkRelationships(for: rows)
		replaceLinkTitlesIfPossible(rows: rows)
		outlineContentDidChange()

		guard isBeingViewed else { return }

		var changes = rebuildShadowTable()
		
		if let reload = afterRow?.shadowTableIndex {
			reloads.insert(reload)
		}
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		
		outlineElementsDidChange(changes)
	}

	public func createRowsInsideAtStart(_ rows: [Row], afterRowContainer: RowContainer, rowStrings: RowStrings? = nil) {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}
		
		if let texts = rowStrings, let afterRow = afterRowContainer as? Row {
			updateRowStrings(afterRow, texts)
		}
		
		resetPreviouslyUsed(rows: rows)

		var reloads = Set<Int>()

		for row in rows.reversed() {
			afterRowContainer.insertRow(row, at: 0)
			row.parent = afterRowContainer
						
			if let parentRow = row.parent as? Row, autoCompleteUncomplete(row: parentRow) {
				if let parentRowIndex = parentRow.shadowTableIndex {
					reloads.insert(parentRowIndex)
				}
			}
		}
		
		createLinkRelationships(for: rows)
		replaceLinkTitlesIfPossible(rows: rows)
		outlineContentDidChange()

		guard isBeingViewed else { return }

		var changes = rebuildShadowTable()
		
		if let reload = (afterRowContainer as? Row)?.shadowTableIndex {
			reloads.insert(reload)
		}

		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		changes.newCursorIndex = rows.last?.shadowTableIndex
		outlineElementsDidChange(changes)
	}
	
	public func createRowsInsideAtEnd(_ rows: [Row], afterRowContainer: RowContainer) {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}

		resetPreviouslyUsed(rows: rows)

		var reloads = Set<Int>()

		for row in rows {
			afterRowContainer.appendRow(row)
			row.parent = afterRowContainer
			
			if let parentRow = row.parent as? Row, autoCompleteUncomplete(row: parentRow) {
				if let parentRowIndex = parentRow.shadowTableIndex {
					reloads.insert(parentRowIndex)
				}
			}
		}
		
		createLinkRelationships(for: rows)
		replaceLinkTitlesIfPossible(rows: rows)
		outlineContentDidChange()

		guard isBeingViewed else { return  }

		var changes = rebuildShadowTable()
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		outlineElementsDidChange(changes)
	}

	public func createRowsDirectlyAfter(_ rows: [Row], afterRow: Row) {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}

		resetPreviouslyUsed(rows: rows)

		var reloads = Set<Int>()

		if let afterRowParent = afterRow.parent, let afterRowChildIndex = afterRowParent.firstIndexOfRow(afterRow) {
			for (i, row) in rows.enumerated() {
				afterRowParent.insertRow(row, at: afterRowChildIndex + i + 1)
				row.parent = afterRowParent

				if let parentRow = row.parent as? Row, autoCompleteUncomplete(row: parentRow) {
					if let parentRowIndex = parentRow.shadowTableIndex {
						reloads.insert(parentRowIndex)
					}
				}
			}
		}
		
		createLinkRelationships(for: rows)
		replaceLinkTitlesIfPossible(rows: rows)
		outlineContentDidChange()

		guard isBeingViewed else { return }

		var changes = rebuildShadowTable()
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		outlineElementsDidChange(changes)
	}

	public func isCreateRowOutsideUnavailable(rows: [Row]) -> Bool {
		return isMoveRowsLeftUnavailable(rows: rows)
	}
	
	public func createRowsOutside(_ rows: [Row], afterRow: Row, rowStrings: RowStrings? = nil) {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}

		resetPreviouslyUsed(rows: rows)

		if let texts = rowStrings {
			updateRowStrings(afterRow, texts)
		}
		
		guard let afterParentRow = afterRow.parent as? Row,
			  let afterParentRowParent = afterParentRow.parent,
			  let index = afterParentRowParent.firstIndexOfRow(afterParentRow) else {
			return
		}
		
		var reloads = Set<Int>()

		for (i, row) in rows.enumerated() {
			afterParentRowParent.insertRow(row, at: index + i + 1)
			row.parent = afterParentRowParent
			
			if let parentRow = row.parent as? Row, autoCompleteUncomplete(row: parentRow) {
				if let parentRowIndex = parentRow.shadowTableIndex {
					reloads.insert(parentRowIndex)
				}
			}
		}

		createLinkRelationships(for: rows)
		replaceLinkTitlesIfPossible(rows: rows)
		outlineContentDidChange()

		guard isBeingViewed else { return }

		var changes = rebuildShadowTable()
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		changes.newCursorIndex = rows.last?.shadowTableIndex
		outlineElementsDidChange(changes)
	}

	func duplicateRows(_ rows: [Row]) -> [Row] {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}

		var newRows = [Row]()
		var idDict = [String: Row]()
		
		let sortedRows = rows.sortedWithDecendentsFiltered().sortedByReverseDisplayOrder()
		guard let afterRow = sortedRows.first else { return newRows }
		
		func duplicatingVisitor(_ visited: Row) {
			let newRow = visited.duplicate(newOutline: self)
			newRow.rowOrder = OrderedSet<String>()
			
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
		
		guard isBeingViewed else { return newRows }

		outlineContentDidChange()
		outlineElementsDidChange(rebuildShadowTable())

		return newRows
	}

	func splitRow(newRow: Row, toParent: RowContainer? = nil, toIndex: Int? = nil, row: Row, topic: NSAttributedString, cursorPosition: Int) {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}

		let newTopicRange = NSRange(location: cursorPosition, length: topic.length - cursorPosition)
		let newTopicText = topic.attributedSubstring(from: newTopicRange)
		newRow.topic = newTopicText
		
		let topicRange = NSRange(location: 0, length: cursorPosition)
		let topicText = topic.attributedSubstring(from: topicRange)

		let newCursorIndex = createRow(newRow, parent: toParent, index: toIndex, afterRow: row, rowStrings: .topic(topicText))
		
		guard isBeingViewed else { return }
		guard let rowShadowTableIndex = row.shadowTableIndex else { return }
		
		var changes = rebuildShadowTable()
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: Set([rowShadowTableIndex])))
		changes.newCursorIndex = newCursorIndex
		changes.cursorMoveIsToStart = true
		outlineElementsDidChange(changes)
	}

	public func updateRow(_ row: Row, rowStrings: RowStrings?, applyChanges: Bool) {
		if let texts = rowStrings {
			updateRowStrings(row, texts)
		}
		
		outlineContentDidChange()
		
		if isBeingViewed && applyChanges {
			guard let shadowTableIndex = row.shadowTableIndex else { return }
			let changes = OutlineElementChanges(section: adjustedRowsSection, reloads: [shadowTableIndex])
			outlineElementsDidChange(changes)
		}
	}
	
	@discardableResult
	public func expand(rows: [Row]) -> [Row] {
		let expandableRows = rows.filter { $0.isExpandable }
		
		expandAllInOutlineUnavailableNeedsUpdate = true
		collapseAllInOutlineUnavailableNeedsUpdate = true

		if rowCount == 1, let row = expandableRows.first {
			expand(row: row)
			return [row]
		}
		
		return expandCollapse(rows: expandableRows, isExpanded: true)
	}
	
	@discardableResult
	public func collapse(rows: [Row]) -> [Row] {
		let collapsableRows = rows.filter { $0.isCollapsable }

		expandAllInOutlineUnavailableNeedsUpdate = true
		collapseAllInOutlineUnavailableNeedsUpdate = true
		
		if rowCount == 1, let row = collapsableRows.first {
			collapse(row: row)
			return [row]
		}
		
		return expandCollapse(rows: collapsableRows, isExpanded: false)
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
		
		guard isBeingViewed else {
			return impacted
		}

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

		guard isBeingViewed else {
			return impacted
		}

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
	
	public func complete(rows: [Row], rowStrings: RowStrings? = nil) {
		completeUncomplete(rows: rows, isComplete: true, rowStrings: rowStrings)
	}
	
	public func isUncompleteUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if row.isUncompletable {
				return false
			}
		}
		return true
	}
	
	public func uncomplete(rows: [Row], rowStrings: RowStrings? = nil) {
		completeUncomplete(rows: rows, isComplete: false, rowStrings: rowStrings)
	}
	
	public func isMoveRowsRightUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if let rowIndex = row.parent?.firstIndexOfRow(row), rowIndex > 0 {
				return false
			}
		}
		return true
	}
	
	func moveRowsRight(_ rows: [Row], rowStrings: RowStrings?) -> [Row] {
		collapseAllInOutlineUnavailableNeedsUpdate = true

		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}

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
				  let newParentRow = row.parent?.rows[rowIndex - 1] else { continue }

			impacted.append(row)
			expand(row: newParentRow)
			
			// Don't grab this until we expand or it won't be correctly recalculated
			guard let rowShadowTableIndex = row.shadowTableIndex else { continue }
			
			row.parent = newParentRow
			container.removeRow(row)
			newParentRow.appendRow(row)

			newParentRow.isExpanded = true

			autoCompleteUncomplete(row: newParentRow)
			
			// If the new parent row doesn't have a shadow table index, it is because it is filtered
			if let newParentRowShadowTableIndex = newParentRow.shadowTableIndex {
				reloads.insert(newParentRowShadowTableIndex)
				reloads.insert(rowShadowTableIndex)
			} else {
				shadowTable?.remove(at: rowShadowTableIndex)
				deletes.insert(rowShadowTableIndex)
			}
		}
		
		outlineContentDidChange()
		
		guard isBeingViewed else {
			return impacted
		}
		
		reloads.formUnion(reloadsForAncestorAndChildren(rows: impacted))
		let changes = OutlineElementChanges(section: adjustedRowsSection, deletes: deletes, reloads: reloads)
		outlineElementsDidChange(changes)
		return impacted
	}
	
	public func isMoveRowsLeftUnavailable(rows: [Row]) -> Bool {
		for row in rows {
			if row.currentLevel != 0 {
				return false
			}
		}
		return true
	}
		
	@discardableResult
	func moveRowsLeft(_ rows: [Row], rowStrings: RowStrings?) -> [Row] {
		collapseAllInOutlineUnavailableNeedsUpdate = true

		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}

		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}

		var impacted = [Row]()
		var reloads = Set<Int>()
		
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

			if autoCompleteUncomplete(row: oldParent) {
				if let parentRowIndex = oldParent.shadowTableIndex {
					reloads.insert(parentRowIndex)
				}
			}
		}

		outlineContentDidChange()
		
		guard isBeingViewed else {
			return impacted
		}

		var changes = rebuildShadowTable()
		reloads.formUnion(reloadsForAncestorAndChildren(rows: impacted))
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
		defer {
			endCloudKitBatchRequest()
		}

		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}

		for row in rows.sortedByDisplayOrder() {
			if let parent = row.parent, let index = parent.firstIndexOfRow(row), index - 1 > -1 {
				parent.removeRow(row)
				parent.insertRow(row, at: index - 1)
			}
		}
		
		outlineContentDidChange()
   
		guard isBeingViewed else { return }

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
		defer {
			endCloudKitBatchRequest()
		}

		if rowCount == 1, let row = rows.first, let texts = rowStrings {
			updateRowStrings(row, texts)
		}

		for row in rows.sortedByReverseDisplayOrder() {
			if let parent = row.parent, let index = parent.firstIndexOfRow(row), index + 1 < parent.rowCount {
				parent.removeRow(row)
				parent.insertRow(row, at: index + 1)
			}
		}
		
		outlineContentDidChange()
		
		guard isBeingViewed else { return }

		outlineElementsDidChange(rebuildShadowTable())
	}
	
	public func moveRowsInsideAtStart(_ rows: [Row], afterRowContainer: RowContainer) {
		var rowMoves = [RowMove]()
		for (index, row) in rows.enumerated() {
			rowMoves.append(RowMove(row: row, toParent: afterRowContainer, toChildIndex: index))
		}
		moveRows(rowMoves)
	}
	
	public func moveRowsInsideAtEnd(_ rows: [Row], afterRowContainer: RowContainer) {
		var rowMoves = [RowMove]()
		for (index, row) in rows.enumerated() {
			rowMoves.append(RowMove(row: row, toParent: afterRowContainer, toChildIndex: index + afterRowContainer.rowCount))
		}
		moveRows(rowMoves)
	}
	
	public func moveRowsOutside(_ rows: [Row], afterRow: Row) {
		guard let afterRowParent = afterRow.parent as? Row,
			  let afterRowGrandParent = afterRowParent.parent,
			  let startIndex = afterRowGrandParent.firstIndexOfRow(afterRowParent) else { return }
		
		var rowMoves = [RowMove]()
		for (index, row) in rows.enumerated() {
			rowMoves.append(RowMove(row: row, toParent: afterRowGrandParent, toChildIndex: index + startIndex + 1))
		}
		moveRows(rowMoves)
	}

	public func moveRowsDirectlyAfter(_ rows: [Row], afterRow: Row) {
		guard let afterRowParent = afterRow.parent,
			  let startIndex = afterRowParent.firstIndexOfRow(afterRow) else { return }
		
		var rowMoves = [RowMove]()
		for (index, row) in rows.enumerated() {
			rowMoves.append(RowMove(row: row, toParent: afterRowParent, toChildIndex: index + startIndex + 1))
		}
		moveRows(rowMoves)
	}

	func moveRows(_ rowMoves: [RowMove], rowStrings: RowStrings? = nil) {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}

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
			
			if let parentRow = rowMove.row.parent as? Row, autoCompleteUncomplete(row: parentRow) {
				if let parentRowIndex = parentRow.shadowTableIndex {
					oldParentReloads.insert(parentRowIndex)
				}
			}

			if let oldParentShadowTableIndex = (rowMove.row.parent as? Row)?.shadowTableIndex {
				oldParentReloads.insert(oldParentShadowTableIndex)
			}
			
			if rowMove.toChildIndex >= rowMove.toParent.rowCount {
				rowMove.toParent.appendRow(rowMove.row)
			} else {
				rowMove.toParent.insertRow(rowMove.row, at: rowMove.toChildIndex)
			}

			if let parentRow = rowMove.toParent as? Row {
				autoCompleteUncomplete(row: parentRow)
			}
		}

		outlineContentDidChange()

		guard isBeingViewed else { return }

		var changes = rebuildShadowTable()
		var reloads = reloadsForAncestorAndChildren(rows: rowMoves.map { $0.row })
		reloads.formUnion(oldParentReloads)
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		outlineElementsDidChange(changes)
	}
	
	public func load(includeImages: Bool = true) {
		beingUsedCount = beingUsedCount + 1
		
		guard rowsFile == nil, beingUsedCount == 1 else { return }

		rowsFile = RowsFile(outline: self)
		rowsFile?.load()

		if includeImages {
			imagesFile = ImagesFile(outline: self)
			imagesFile?.load()
		}
		
		prepareRowsForProcessing()
	}
	
	public func unload() async {
		beingUsedCount = beingUsedCount - 1

		guard beingUsedCount > -1 else { fatalError("This Outline was unloaded more times than it was loaded.") }
		
		guard beingUsedCount == 0 else { return }

		await rowsFile?.saveIfNecessary()
		rowsFile?.suspend()
		rowsFile = nil
		shadowTable = nil
		rowOrder = nil
		keyedRows = nil

		await imagesFile?.saveIfNecessary()
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
	
	public func save() async {
		await rowsFile?.saveIfNecessary()
		await imagesFile?.saveIfNecessary()
	}
	
	public func forceSave() async {
		if rowsFile == nil {
			rowsFile = RowsFile(outline: self)
		}
		
		rowsFile?.markAsDirty()
		await rowsFile?.saveIfNecessary()
		
		imagesFile?.markAsDirty()
		await imagesFile?.saveIfNecessary()
	}
	
	public func delete() {
		for link in documentLinks ?? [EntityID]() {
			if let outline = account?.accountManager?.findDocument(link)?.outline {
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
	
	public func duplicate(account: Account) -> Outline {
		let outline = Outline(account: account, id: .document(account.id.accountID, UUID().uuidString))

		outline.title = title
		outline.ownerName = ownerName
		outline.ownerEmail = ownerEmail
		outline.ownerURL = ownerURL
		outline.isFilterOn = isFilterOn
		outline.isCompletedFiltered = isCompletedFiltered
		outline.isNotesFiltered = isNotesFiltered
		outline.tagIDs = tagIDs
		outline.documentLinks = documentLinks
		
		for linkedDocumentID in outline.documentLinks ?? [EntityID]() {
			if let linkedOutline = account.accountManager?.findDocument(linkedDocumentID)?.outline {
				linkedOutline.createBacklink(outline.id)
			}
		}
		
		guard let keyedRows else { return outline }

		var rowIDMap = [String: String]()
		var newKeyedRows = [String: Row]()
		for key in keyedRows.keys {
			if let row = keyedRows[key] {
				let duplicateRow = row.duplicate(newOutline: outline)
				newKeyedRows[duplicateRow.id] = duplicateRow
				rowIDMap[row.id] = duplicateRow.id
			}
		}
		
		var newRowOrder = OrderedSet<String>()
		for orderKey in rowOrder ?? OrderedSet<String>() {
			if let newKey = rowIDMap[orderKey] {
				newRowOrder.append(newKey)
			}
		}
		outline.rowOrder = newRowOrder
		
		var updatedNewKeyedRows = [String: Row]()
		for key in newKeyedRows.keys {
			if let newKeyedRow = newKeyedRows[key] {
				var updatedRowOrder = OrderedSet<String>()
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
	
	func createBacklink(_ entityID: EntityID) {
		if isCloudKit && ancestorDocumentBacklinks == nil {
			ancestorDocumentBacklinks = documentBacklinks
		}

		if documentBacklinks == nil {
			documentBacklinks = [EntityID]()
		}
				
		documentBacklinks?.append(entityID)
		documentMetaDataDidChange()
		
		requestCloudKitUpdate(for: id)

		guard isBeingViewed else { return }

		if documentBacklinks?.count ?? 0 == 1 {
			outlineAddedBacklinks()
		} else {
			if isSearching == .notSearching {
				outlineElementsDidChange(OutlineElementChanges(section: Section.backlinks, reloads: Set([0])))
			}
		}
	}

	func deleteBacklink(_ entityID: EntityID) {
		if isCloudKit && ancestorDocumentBacklinks == nil {
			ancestorDocumentBacklinks = documentBacklinks
		}

		documentBacklinks?.removeFirst(object: entityID)
		documentMetaDataDidChange()
		
		requestCloudKitUpdate(for: id)

		guard isBeingViewed else { return }
		
		if documentBacklinks?.count ?? 0 == 0 {
			outlineRemovedBacklinks()
		} else {
			if isSearching == .notSearching {
				outlineElementsDidChange(OutlineElementChanges(section: Section.backlinks, reloads: Set([0])))
			}
		}
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
		
	public func fixAltLinks() {
		guard hasAltLinks ?? false else { return }
		
		load()
		
		if let keyedRows {
			beginCloudKitBatchRequest()
			defer {
				endCloudKitBatchRequest()
			}

			var cumulativeActionsTaken = AltLinkResolvingActions()
			
			for row in keyedRows.values {
				let actionsTaken = row.resolveAltLinks()
				cumulativeActionsTaken.formUnion(actionsTaken)
				
				if actionsTaken.contains(.fixedAltLink) {
					createLinkRelationships(for: [row])
					requestCloudKitUpdate(for: row.entityID)
					outlineContentDidChange()
				}
			}
			
			if !cumulativeActionsTaken.contains(.foundAltLink) {
				hasAltLinks = false
				requestCloudKitUpdate(for: id)
			}
		}
		
		Task {
			await unload()
		}
		
	}
	
	func rebuildShadowTable() -> OutlineElementChanges {
		guard let oldShadowTable = shadowTable else { return OutlineElementChanges(section: adjustedRowsSection) }
		let reloads = rebuildTransientData()
		
		var moves = Set<OutlineElementChanges.Move>()
		var inserts = Set<Int>()
		var deletes = Set<Int>()
		
		let diff = shadowTable!.difference(from: oldShadowTable).inferringMoves()
		for change in diff {
			switch change {
			case .insert(let offset, _, let associated):
				if let associated {
					moves.insert(OutlineElementChanges.Move(associated, offset))
				} else {
					inserts.insert(offset)
				}
			case .remove(let offset, _, let associated):
				if let associated {
					moves.insert(OutlineElementChanges.Move(offset, associated))
				} else {
					deletes.insert(offset)
				}
			}
		}
		
		return OutlineElementChanges(section: adjustedRowsSection, deletes: deletes, inserts: inserts, moves: moves, reloads: reloads)
	}
	
	func toCoder() -> OutlineCoder {
		return OutlineCoder(cloudKitMetaData: cloudKitMetaData,
							id: id, 
							ancestorTitle: ancestorTitle,
							title: title,
							ancestorDisambiguator: ancestorDisambiguator,
							disambiguator: disambiguator,
							ancestorCreated: ancestorCreated,
							created: created,
							ancestorUpdated: ancestorUpdated,
							updated: updated,
							ancestorNumberingStyle: ancestorNumberingStyle,
							numberingStyle: numberingStyle,
							ancestorAutomaticallyCreateLinks: ancestorAutomaticallyCreateLinks,
							automaticallyCreateLinks: automaticallyCreateLinks,
							ancestorAutomaticallyChangeLinkTitles: ancestorAutomaticallyChangeLinkTitles,
							automaticallyChangeLinkTitles: automaticallyChangeLinkTitles,
							ancestorCheckSpellingWhileTyping: ancestorCheckSpellingWhileTyping,
							checkSpellingWhileTyping: checkSpellingWhileTyping,
							ancestorCorrectSpellingAutomatically: ancestorCorrectSpellingAutomatically,
							correctSpellingAutomatically: correctSpellingAutomatically,
							ancestorOwnerName: ancestorOwnerName,
							ownerName: ownerName,
							ancestorOwnerEmail: ancestorOwnerEmail,
							ownerEmail: ownerEmail,
							ancestorOwnerURL: ancestorOwnerURL,
							ownerURL: ownerURL,
							verticleScrollState: verticleScrollState,
							isFilterOn: isFilterOn,
							isCompletedFiltered: isCompletedFiltered, 
							isNotesFiltered: isNotesFiltered,
							focusRowID: focusRowID,
							selectionRowID: selectionRowID,
							selectionIsInNotes: selectionIsInNotes,
							selectionLocation: selectionLocation,
							selectionLength: selectionLength,
							ancestorTagIDs: ancestorTagIDs,
							tagIDs: tagIDs,
							ancestorDocumentLinks: ancestorDocumentLinks,
							documentLinks: documentLinks,
							ancestorDocumentBacklinks: ancestorDocumentBacklinks,
							documentBacklinks: documentBacklinks,
							ancestorHasAltLinks: ancestorHasAltLinks,
							hasAltLinks: hasAltLinks,
							cloudKitZoneName: cloudKitZoneName,
							cloudKitZoneOwner: cloudKitZoneOwner,
							cloudKitShareRecordName: cloudKitShareRecordName,
							cloudKitShareRecordData: cloudKitShareRecordData)
	}
	
	func documentTitleDidChange() {
		NotificationCenter.default.post(name: .DocumentTitleDidChange, object: Document.outline(self), userInfo: nil)
	}
	
	func outlineAddedBacklinks() {
		NotificationCenter.default.post(name: .OutlineAddedBacklinks, object: self, userInfo: nil)
	}
	
	func outlineRemovedBacklinks() {
		NotificationCenter.default.post(name: .OutlineRemovedBacklinks, object: self, userInfo: nil)
	}
	
	func outlineDidDelete() {
		NotificationCenter.default.post(name: .DocumentDidDelete, object: Document.outline(self), userInfo: nil)
	}
	
	func outlineElementsDidChange(_ changes: OutlineElementChanges) {
		guard isBeingViewed else { return }
		
		var userInfo = [AnyHashable: Any]()
		userInfo[OutlineElementChanges.userInfoKey] = changes
		NotificationCenter.default.post(name: .OutlineElementsDidChange, object: self, userInfo: userInfo)
	}
	
	nonisolated public static func == (lhs: Outline, rhs: Outline) -> Bool {
		return lhs.id == rhs.id
	}
	
	nonisolated public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
}

// MARK: Helpers

private extension Outline {
	
	func documentUpdatedDidChange() {
		NotificationCenter.default.post(name: .DocumentUpdatedDidChange, object: Document.outline(self), userInfo: nil)
	}

	func documentMetaDataDidChange() {
		NotificationCenter.default.post(name: .DocumentMetaDataDidChange, object: Document.outline(self), userInfo: nil)
	}

	func documentSharingDidChange() {
		NotificationCenter.default.post(name: .DocumentSharingDidChange, object: Document.outline(self), userInfo: nil)
	}

	func outlineContentDidChange() {
		self.updated = Date()
		requestCloudKitUpdate(for: id)
		rowsFile?.markAsDirty()
	}
	
	func outlineViewPropertyDidChange() {
		documentMetaDataDidChange()
		rowsFile?.markAsDirty()
	}
	
	func outlineTagsDidChange() {
		NotificationCenter.default.post(name: .OutlineTagsDidChange, object: self, userInfo: nil)
	}
	
	func outlineTextPreferencesDidChange() {
		NotificationCenter.default.post(name: .OutlineTextPreferencesDidChange, object: self, userInfo: nil)
	}
	
	func outlineSearchWillBegin() {
		NotificationCenter.default.post(name: .OutlineSearchWillBegin, object: self, userInfo: nil)
	}
	
	func outlineSearchResultDidChange() {
		NotificationCenter.default.post(name: .OutlineSearchResultDidChange, object: self, userInfo: nil)
	}
	
	func outlineSearchWillEnd() {
		NotificationCenter.default.post(name: .OutlineSearchWillEnd, object: self, userInfo: nil)
	}
	
	func outlineSearchDidEnd() {
		NotificationCenter.default.post(name: .OutlineSearchDidEnd, object: self, userInfo: nil)
	}
	
	func outlineDidFocusOut() {
		NotificationCenter.default.post(name: .OutlineDidFocusOut, object: self, userInfo: nil)
	}
	
	func changeSearchResult(_ changeToResult: Int) {
		var reloads = Set<Int>()
		
		if currentSearchResult != -1 {
			let currentCoordinates = searchResultCoordinates[currentSearchResult]
			currentCoordinates.isCurrentResult = false
			if let shadowTableIndex = currentCoordinates.row.shadowTableIndex {
				reloads.insert(shadowTableIndex)
			}
		}
		
		let changeToCoordinates = searchResultCoordinates[changeToResult]
		changeToCoordinates.isCurrentResult = true
		if let shadowTableIndex = changeToCoordinates.row.shadowTableIndex {
			reloads.insert(shadowTableIndex)
		}

		currentSearchResult = changeToResult
		
		outlineElementsDidChange(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		outlineSearchResultDidChange()
	}
	
	func clearSearchResults() {
		let reloads = Set(searchResultCoordinates.compactMap({ $0.row.shadowTableIndex }))
		
		currentSearchResult = -1
		searchResultCoordinates = .init()

		guard isBeingViewed else { return }
		
		func clearSearchVisitor(_ visited: Row) {
			visited.clearSearchResults()
			visited.rows.forEach { $0.visit(visitor: clearSearchVisitor) }
		}
		rows.forEach { $0.visit(visitor: clearSearchVisitor(_:)) }
		
		outlineElementsDidChange(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
	}
	
	func completeUncomplete(rows: [Row], isComplete: Bool, rowStrings: RowStrings?) {
		beginCloudKitBatchRequest()
		defer {
			endCloudKitBatchRequest()
		}

		if rowCount > 0, let row = rows.first, let texts = rowStrings {
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
				if let parentRow = row.parent as? Row, autoCompleteUncomplete(row: parentRow) {
					impacted.append(parentRow)
				}
				impacted.append(row)
			}
		}
		
		outlineContentDidChange()

		guard isBeingViewed else { return }

		if isCompletedFilterOn {
			var changes = rebuildShadowTable()
			if let firstComplete = changes.deletes?.sorted().first, firstComplete > 0 {
				changes.newCursorIndex = firstComplete - 1
			} else {
				changes.newCursorIndex = 0
			}
			outlineElementsDidChange(changes)
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
	}
	
	@discardableResult
	func autoCompleteUncomplete(row: Row) -> Bool {
		if row.isAutoCompletable {
			completeUncomplete(rows: [row], isComplete: true, rowStrings: nil)
			return true
		}

		if row.isAutoUncompletable {
			completeUncomplete(rows: [row], isComplete: false, rowStrings: nil)
			return true
		}
		
		return false
	}

	func isExpandAllUnavailable(container: RowContainer) -> Bool {
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
	
	func expandCollapse(rows: [Row], isExpanded: Bool) -> [Row] {
		var impacted = [Row]()
		
		for row in rows {
			if isExpanded != row.isExpanded {
				row.isExpanded = isExpanded
				impacted.append(row)
			}
		}
		
		outlineViewPropertyDidChange()
		
		guard isBeingViewed else { return impacted }

		var changes = rebuildShadowTable()
		
		let reloads = Set(rows.compactMap { $0.shadowTableIndex })
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: reloads))
		
		outlineElementsDidChange(changes)
		return impacted
	}
	
	func expand(row: Row) {
		guard !row.isExpanded, let rowShadowTableIndex = row.shadowTableIndex else { return }
		
		row.isExpanded = true

		outlineViewPropertyDidChange()
		
		guard isBeingViewed else { return }

		var changes = rebuildShadowTable()
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: [rowShadowTableIndex]))
					   
		outlineElementsDidChange(changes)
	}

	func isCollapseAllUnavailable(container: RowContainer) -> Bool {
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
	
	func collapse(row: Row)  {
		guard row.isExpanded else { return  }

		row.isExpanded = false
			
		outlineViewPropertyDidChange()
		
		guard isBeingViewed else { return }
		guard let rowShadowTableIndex = row.shadowTableIndex else { return }

		var changes = rebuildShadowTable()
		changes.append(OutlineElementChanges(section: adjustedRowsSection, reloads: [rowShadowTableIndex]))

		outlineElementsDidChange(changes)
	}
	
	func prepareRowsForProcessing() {
		func visitor(_ visited: Row) {
			visited.rows.forEach { row in
				row.parent = visited
				row.visit(visitor: visitor)
			}
		}
		
		rows.forEach { row in
			row.parent = self
			row.visit(visitor: visitor(_:))
		}
	}
	
	@discardableResult
	func rebuildTransientData() -> Set<Int> {
		let reloadMovedRows = (numberingStyle ?? .none) != .none
		let transient = TransientDataVisitor(isCompletedFilterOn: isCompletedFilterOn, isSearching: isSearching, reloadMovedRows: reloadMovedRows)
		
		if let focusRow {
			focusRow.visit(visitor: transient.visitor(_:))
		} else {
			rows.forEach { row in
				row.parent = self
				row.visit(visitor: transient.visitor(_:))
			}
		}
		
		self.shadowTable = transient.shadowTable
		
		return transient.reloads
	}
	
	func reloadsForAncestorAndChildren(rows: [Row]) -> Set<Int> {
		var reloads = Set<Int>()
		
		for row in rows {
			func reloadVisitor(_ visited: Row) {
				if let index = visited.shadowTableIndex {
					reloads.insert(index)
				}
				if visited.isExpanded {
					visited.rows.forEach { $0.visit(visitor: reloadVisitor) }
				}
			}

			// For indenting, outdenting and moving we alway reload the parent because its
			// disclosure may need to be shown or hidden
			if let parentShadowTableIndex = (row.parent as? Row)?.shadowTableIndex {
				reloads.insert(parentShadowTableIndex)
			}
			
			// Indents need to reload the grand parent to reload any numbering styles that may
			// have changed. Outdents only need to go up as high as the parent.
			if let grandParent = (row.parent as? Row)?.parent {
				grandParent.rows.forEach { $0.visit(visitor: reloadVisitor(_:)) }
			} else {
				row.parent?.rows.forEach { $0.visit(visitor: reloadVisitor(_:)) }
			}
		}

		return reloads
	}
	
	// When creating rows that previously existed, we need to strip the cloudKitMetadata or they won't sync. A prime example
	// of this is when we delete some rows and then undelete them. The undeleted rows must have their metadata stripped so that
	// CloudKit doesn't consider them "not found" records and recreates them.
	func resetPreviouslyUsed(rows: [Row]) {
		for row in rows {
			row.cloudKitMetaData = nil
		}
	}
	
	func deleteLinkRelationships(for rows: [Row]) {
		rows.forEach { row in
			if let topic = row.topic {
				extractLinkToIDs(topic).forEach { deleteLinkRelationship($0) }
			}
			if let note = row.note {
				extractLinkToIDs(note).forEach { deleteLinkRelationship($0) }
			}
		}
	}

	func createLinkRelationships(for rows: [Row]) {
		rows.forEach { row in
			if let topic = row.topic {
				extractLinkToIDs(topic).forEach { createLinkRelationship($0) }
			}
			if let note = row.note {
				extractLinkToIDs(note).forEach { createLinkRelationship($0) }
			}
		}
	}

	func updateRowStrings(_ row: Row, _ rowStrings: RowStrings) {
		let oldTopic = row.topic
		let oldNote = row.note

		row.rowStrings = rowStrings

		row.detectData()
		
		switch rowStrings {
		case .topicMarkdown, .topic:
			processLinkDiff(oldText: oldTopic, newText: row.topic)
			replaceLinkTitleIfPossible(row: row, newText: row.topic, isInNotes: false)
		case .noteMarkdown, .note:
			processLinkDiff(oldText: oldNote, newText: row.note)
			replaceLinkTitleIfPossible(row: row, newText: row.note, isInNotes: true)
		case .both:
			processLinkDiff(oldText: oldTopic, newText: row.topic)
			processLinkDiff(oldText: oldNote, newText: row.note)
			replaceLinkTitleIfPossible(row: row, newText: row.topic, isInNotes: false)
			replaceLinkTitleIfPossible(row: row, newText: row.note, isInNotes: true)
		}

	}
	
	func processLinkDiff(oldText: NSAttributedString?, newText: NSAttributedString?) {
		let oldTextDocLinks = oldText != nil ? extractLinkToIDs(oldText!) : [EntityID]()
		let newTextDocLinks = newText != nil ? extractLinkToIDs(newText!) : [EntityID]()
		let topicDiff = newTextDocLinks.difference(from: oldTextDocLinks)
		processLinkDiff(topicDiff)
	}
	
	func processLinkDiff(_ diff: CollectionDifference<EntityID>) {
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
	
	func createLinkRelationship(_ entityID: EntityID) {
		guard let outline = account?.accountManager?.findDocument(entityID)?.outline else { return }
		
		if isCloudKit && ancestorDocumentLinks == nil {
			ancestorDocumentLinks = documentLinks
		}

		outline.createBacklink(id)
		if documentLinks == nil {
			documentLinks = [EntityID]()
		}
		documentLinks?.append(entityID)

		documentMetaDataDidChange()
		requestCloudKitUpdate(for: id)
	}

	func deleteLinkRelationship(_ entityID: EntityID) {
		guard let outline = account?.accountManager?.findDocument(entityID)?.outline else { return }

		if isCloudKit && ancestorDocumentLinks == nil {
			ancestorDocumentLinks = documentLinks
		}

		outline.deleteBacklink(id)
		documentLinks?.removeFirst(object: entityID)

		documentMetaDataDidChange()
		requestCloudKitUpdate(for: id)
	}

	func extractLinkToIDs(_ attrString: NSAttributedString) -> [EntityID] {
		var ids = [EntityID]()
		attrString.enumerateAttribute(.link, in:  NSRange(0..<attrString.length)) { value, range, stop in
			if let url = value as? URL, let id = EntityID(url: url) {
				ids.append(id)
			}
		}
		return ids
	}
	
	func replaceLinkTitlesIfPossible(rows: [Row]) {
		for row in rows {
			replaceLinkTitleIfPossible(row: row, newText: row.topic, isInNotes: false)
			replaceLinkTitleIfPossible(row: row, newText: row.note, isInNotes: true)
		}
	}
	
	func replaceLinkTitleIfPossible(row: Row, newText: NSAttributedString?, isInNotes: Bool) {
		guard automaticallyChangeLinkTitles ?? false, let newText else { return }
		
		load()
		
		Task { @MainActor in
			let pageTitles = await withTaskGroup(of: (URL, String?).self, returning: [URL: String].self) { taskGroup in
				newText.enumerateAttribute(.link, in: NSRange(location: 0, length: newText.length)) { (value, range, match) in
					guard let url = value as? URL else { return }
					
					taskGroup.addTask {
						let pageTitle = await WebPageTitle.find(forURL: url)
						return (url, pageTitle)
					}
				}
				
				var pageTitles = [URL: String]()
				for await result in taskGroup {
					if let pageTitle = result.1 {
						pageTitles[result.0] = pageTitle
					}
				}
				return pageTitles
			}
			
			let mutableText = NSMutableAttributedString(attributedString: newText)
			
			mutableText.enumerateAttribute(.link, in: NSRange(location: 0, length: mutableText.length)) { (value, range, match) in
				guard let url = value as? URL,
					  let pageTitle = pageTitles[url],
					  mutableText.attributedSubstring(from: range).string == url.absoluteString else {
					return
				}
				
				mutableText.removeAttribute(.link, range: range)
				mutableText.replaceCharacters(in: range, with: pageTitle)
				mutableText.addAttribute(.link, value: url, range: NSRange(location: range.location, length: pageTitle.count))
			}
			
			guard let row = self.findRow(id: row.id) else { return }
			
			if !isInNotes {
				row.topic = mutableText
			} else {
				row.note = mutableText
			}
			
			await self.unload()
			
			if let shadowTableIndex = row.shadowTableIndex {
				self.outlineElementsDidChange(OutlineElementChanges(section: self.adjustedRowsSection, reloads: Set([shadowTableIndex])))
			}
		}
		
	}

	func appendPrintTitle(attrString: NSMutableAttributedString) {
		#if canImport(UIKit)
		if let title {
			let titleFont = UIFont.systemFont(ofSize: 18).with(traits: .traitBold)
			
			var attrs = [NSAttributedString.Key : Any]()
			attrs[.font] = titleFont
			attrs[.foregroundColor] = UIColor.black

			let titleParagraphStyle = NSMutableParagraphStyle()
			titleParagraphStyle.alignment = .center
			titleParagraphStyle.paragraphSpacing = 0.50 * titleFont.lineHeight
			attrs[.paragraphStyle] = titleParagraphStyle
			
			let printTitle = NSMutableAttributedString(string: title)
			printTitle.addAttributes(attrs)
			
			attrString.append(printTitle)
		}
		#endif
	}
	
}

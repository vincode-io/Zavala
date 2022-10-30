//
//  Account.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import UIKit
import CloudKit
import RSCore
import SWXMLHash

public extension Notification.Name {
	static let AccountDidInitialize = Notification.Name(rawValue: "AccountDidInitialize")
	static let AccountMetadataDidChange = Notification.Name(rawValue: "AccountMetadataDidChange")
	static let AccountDocumentsDidChange = Notification.Name(rawValue: "AccountDocumentsDidChange")
	static let AccountTagsDidChange = Notification.Name(rawValue: "AccountTagsDidChange")
}

public enum AccountError: LocalizedError {
	case securityScopeError
	case fileReadError
	
	public var errorDescription: String? {
		switch self {
		case .securityScopeError:
			return TempletonStringAssets.accountErrorScopedResource
		case .fileReadError:
			return TempletonStringAssets.accountErrorImportRead
		}
	}
}

public final class Account: NSObject, Identifiable, Codable, Logging {

	public var id: EntityID {
		return EntityID.account(type.rawValue)
	}
	
	public var name: String {
		return type.name
	}
	
	public var type: AccountType
	public var isActive: Bool
	
	public var tags: [Tag]?
	
	public var documentContainers: [DocumentContainer] {
		var containers = [DocumentContainer]()
		containers.append(AllDocuments(account: self))

		for tagDocuments in tags?
			.sorted(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
			.compactMap({ TagDocuments(account: self, tag: $0) }) ?? [TagDocuments]() {
			containers.append(tagDocuments)
		}
		
		return containers
	}
	
	public private(set) var documents: [Document]?

	enum CodingKeys: String, CodingKey {
		case type = "type"
		case isActive = "isActive"
		case tags = "tags"
		case documents = "documents"
	}
	
	var folder: URL?
	var cloudKitManager: CloudKitManager?
	
	private let operationQueue = OperationQueue()

	private var documentsDictionaryNeedUpdate = true
	private var _idToDocumentsDictionary = [String: Document]()
	private var idToDocumentsDictionary: [String: Document] {
		if documentsDictionaryNeedUpdate {
			rebuildDocumentsDictionary()
		}
		return _idToDocumentsDictionary
	}

	private var tagsDictionaryNeedUpdate = true
	private var _idToTagsDictionary = [String: Tag]()
	private var idToTagsDictionary: [String: Tag] {
		if tagsDictionaryNeedUpdate {
			rebuildTagsDictionary()
		}
		return _idToTagsDictionary
	}

	init(accountType: AccountType) {
		self.type = accountType
		self.isActive = true
		self.documents = [Document]()
	}
	
	func initializeCloudKit(firstTime: Bool, errorHandler: ErrorHandler) {
		cloudKitManager = CloudKitManager(account: self, errorHandler: errorHandler)
		if firstTime {
			cloudKitManager?.firstTimeSetup()
			cloudKitManager?.sync()
		}
	}
	
	public func userDidAcceptCloudKitShareWith(_ shareMetadata: CKShare.Metadata) {
		cloudKitManager?.userDidAcceptCloudKitShareWith(shareMetadata)
	}
	
	public func prepareCloudSharingController(document: Document, completion: @escaping (Result<UICloudSharingController, Error>) -> Void) {
		cloudKitManager?.prepareCloudSharingController(document: document, completion: completion)
	}

	public func activate() {
		guard isActive == false else { return }
		isActive = true
		accountMetadataDidChange()
	}
	
	public func deactivate() {
		guard isActive == true else { return }
		isActive = false
		accountMetadataDidChange()
	}
	
	public func importOPML(_ url: URL, tags: [Tag]?) throws -> Document {
		guard url.startAccessingSecurityScopedResource() else { throw AccountError.securityScopeError }
		defer {
			url.stopAccessingSecurityScopedResource()
		}
		
		var fileData: Data?
		var fileError: NSError? = nil
		NSFileCoordinator().coordinate(readingItemAt: url, error: &fileError) { (url) in
			fileData = try? Data(contentsOf: url)
		}
		
		guard fileError == nil else { throw fileError! }
		guard let opmlData = fileData else { throw AccountError.fileReadError }
		
		return importOPML(opmlData, tags: tags)
	}

	@discardableResult
	public func importOPML(_ opmlData: Data, tags: [Tag]?, images: [String:  Data]? = nil) -> Document {
		let opml = SWXMLHash.config({ config in
			config.caseInsensitive = true
		}).parse(opmlData)["opml"]
		
		let headIndexer = opml["head"]
		let bodyIndexer = opml["body"]
		let outlineIndexers = bodyIndexer["outline"].all
		
		var title = headIndexer["title"].element?.text
		if (title == nil || title!.isEmpty) && outlineIndexers.count > 0 {
			title = outlineIndexers[0].element?.attribute(by: "text")?.text
		}
		if title == nil {
			title = NSLocalizedString("Unavailable", comment: "Unavailable")
		}
		
		let outline = Outline(parentID: id, title: title)
		documents?.append(.outline(outline))
		accountDocumentsDidChange()

		if let created = headIndexer["dateCreated"].element?.text {
			outline.created = Date.dateFromRFC822(rfc822String: created)
		}
		if let updated = headIndexer["dateModified"].element?.text {
			outline.updated = Date.dateFromRFC822(rfc822String: updated)
		}
		outline.ownerName = headIndexer["ownerName"].element?.text
		outline.ownerEmail = headIndexer["ownerEmail"].element?.text
		outline.ownerURL = headIndexer["ownerID"].element?.text
		if let verticleScrollState = headIndexer["vertScrollState"].element?.text {
			outline.verticleScrollState = Int(verticleScrollState)
		}
		
		let tagIndexers = headIndexer["tags"]["tag"].all
		for tagIndexer in tagIndexers {
			if let tagName = tagIndexer.element?.text {
				let tag = createTag(name: tagName)
				outline.createTag(tag)
			}
		}

		if let expansionState = headIndexer["expansionState"].element?.text {
			outline.expansionState = expansionState
		}
		
		for tag in tags ?? [Tag]() {
			outline.createTag(tag)
		}

		outline.importRows(outline: outline, rowIndexers: outlineIndexers, images: images)
		
		outline.zoneID = cloudKitManager?.defaultZone.zoneID
		let document = Document.outline(outline)
		
		disambiguate(document: document)
		
		saveToCloudKit(document)
		
		outline.updateAllLinkRelationships()
		
		fixAltLinks(excluding: outline)
		
		outline.forceSave()
		outline.unloadRows()

		return document
	}
	
	public func disambiguate(document: Document) {
		guard let documents else { return }
		
		if let lastCommon = documents.filter({ $0.title == document.title && $0.id != document.id }).sorted(by: { $0.disambiguator ?? 0 < $1.disambiguator ?? 0 }).last {
			document.update(disambiguator: (lastCommon.disambiguator ?? 1) + 1)
		}
	}
	
	public func createOutline(title: String? = nil, tags: [Tag]? = nil) -> Document {
		let outline = Outline(parentID: id, title: title)
		if documents == nil {
			documents = [Document]()
		}
		
		outline.zoneID = cloudKitManager?.defaultZone.zoneID
		let document = Document.outline(outline)
		documents!.append(document)
		accountDocumentsDidChange()

		if let tags {
            for tag in tags {
                outline.createTag(tag)
            }
		}
		
		disambiguate(document: document)
		
		saveToCloudKit(document)
		
		return document
	}
	
	func apply(_ update: CloudKitOutlineUpdate) {
		guard !update.isDelete else {
			guard let document = findDocument(documentUUID: update.documentID.documentUUID) else { return }
			deleteDocument(document, updateCloudKit: false)
			return
		}
		
		if let document = findDocument(documentUUID: update.documentID.documentUUID) {
			let outline = document.outline!
			outline.load()
			outline.apply(update)
			outline.forceSave()
			outline.unload()
		} else {
			guard update.saveOutlineRecord != nil else {
				return
			}
			let outline = Outline(id: update.documentID)
			outline.zoneID = update.zoneID

			outline.apply(update)
			outline.forceSave()
			outline.unload()
			
			if documents == nil {
				documents = [Document]()
			}
			let document = Document.outline(outline)
			documents!.append(document)
			accountDocumentsDidChange()
		}
	}
	
	public func createDocument(_ document: Document) {
		if documents == nil {
			documents = [Document]()
		}
		
		for tag in document.tags ?? [Tag]() {
			createTag(tag)
		}
		
		var mutableDocument = document
		mutableDocument.zoneID = cloudKitManager?.defaultZone.zoneID
			
		documents!.append(mutableDocument)
		accountDocumentsDidChange()
		saveToCloudKit(mutableDocument)
	}

	public func deleteDocument(_ document: Document) {
		deleteDocument(document, updateCloudKit: true)
	}
	
	public func findDocumentContainer(_ entityID: EntityID) -> DocumentContainer? {
		switch entityID {
		case .allDocuments:
			return AllDocuments(account: self)
		case .recentDocuments:
			return nil
		case .tagDocuments(_, let tagID):
			guard let tag = findTag(tagID: tagID) else { return nil }
			return TagDocuments(account: self, tag: tag)
		default:
			fatalError()
		}
	}

	public func findDocument(_ entityID: EntityID) -> Document? {
		return findDocument(documentUUID: entityID.documentUUID)
	}
	
	public func findDocument(filename: String) -> Document? {
		var title = filename
		var disambiguator: Int? = nil
		
		if let periodIndex = filename.lastIndex(of: ".") {
			title = String(filename.prefix(upTo: periodIndex))
		}
		
		if let underscoreIndex = filename.lastIndex(of: "-") {
			if underscoreIndex < title.endIndex {
				let disambiguatorIndex = title.index(after: underscoreIndex)
				disambiguator = Int(title.suffix(from: disambiguatorIndex))
			}
			title = String(filename.prefix(upTo: underscoreIndex))
		}

		title = title.replacingOccurrences(of: "_", with: " ")
		
		return documents?.filter({ document in
			return document.title == title && document.disambiguator == disambiguator
		}).first
	}
	
	@discardableResult
	public func createTag(name: String) -> Tag {
		if let tag = tags?.first(where: { $0.name == name }) {
			return tag
		}
		
		let tag = Tag(name: name)
		return createTag(tag)
	}
	
	@discardableResult
	func createTag(_ tag: Tag) -> Tag {
		if let tag = tags?.first(where: { $0 == tag }) {
			return tag
		}

		if tags == nil {
			tags = [Tag]()
		}
		
		tags?.append(tag)
		tags?.sort(by: { $0.name < $1.name })
		accountTagsDidChange()
		
		return tag
	}
	
	public func renameTag(_ tag: Tag, to newTagName: String) {
		tag.name = newTagName
		tags?.sort(by: { $0.name < $1.name })
		accountTagsDidChange()

		for doc in documents ?? [Document]() {
			if doc.hasTag(tag) {
				doc.requestCloudKitUpdateForSelf()
			}
		}
	}
	
	public func deleteTag(name: String) {
		guard let tag = tags?.first(where: { $0.name == name }) else {
			return
		}
		deleteTag(tag)
	}

	public func deleteTag(_ tag: Tag) {
		for doc in documents ?? [Document]() {
			if doc.hasTag(tag) {
				return
			}
		}
		
		tags?.removeFirst(object: tag)
		accountTagsDidChange()
	}
	
	public func forceDeleteTag(_ tag: Tag) {
		for doc in documents ?? [Document]() {
			doc.deleteTag(tag)
		}
		
		tags?.removeFirst(object: tag)
		accountTagsDidChange()
	}
	
	public func findTag(name: String) -> Tag? {
		return tags?.first(where: { $0.name == name })
	}

	func findDocument(documentUUID: String) -> Document? {
		return idToDocumentsDictionary[documentUUID]
	}

	func deleteAllDocuments(with zoneID: CKRecordZone.ID) {
		for doc in documents ?? [Document]() {
			if doc.zoneID == zoneID {
				deleteDocument(doc, updateCloudKit: false)
			}
		}
	}
	
	func findTag(tagID: String) -> Tag? {
		return idToTagsDictionary[tagID]
	}

	func fixAltLinks(excluding: Outline) {
		for outline in documents?.compactMap({ $0.outline }) ?? [Outline]() {
			if outline != excluding {
				outline.fixAltLinks()
			}
		}
	}
	
	func accountDidInitialize() {
		NotificationCenter.default.post(name: .AccountDidInitialize, object: self, userInfo: nil)
	}
	
	public static func == (lhs: Account, rhs: Account) -> Bool {
		return lhs.id == rhs.id
	}
	
}

// MARK: NSFilePresenter

extension Account: NSFilePresenter {
	
	public var presentedItemURL: URL? {
		return folder
	}
	
	public var presentedItemOperationQueue: OperationQueue {
		return operationQueue
	}
	
}

// MARK: Helpers

private extension Account {
	
	func accountMetadataDidChange() {
		NotificationCenter.default.post(name: .AccountMetadataDidChange, object: self, userInfo: nil)
	}
	
	func accountDocumentsDidChange() {
		documentsDictionaryNeedUpdate = true
		NotificationCenter.default.post(name: .AccountDocumentsDidChange, object: self, userInfo: nil)
	}
	
	func accountTagsDidChange() {
		tagsDictionaryNeedUpdate = true
		NotificationCenter.default.post(name: .AccountTagsDidChange, object: self, userInfo: nil)
	}
	
	func rebuildDocumentsDictionary() {
		var idDictionary = [String: Document]()
		
		for doc in documents ?? [Document]() {
			idDictionary[doc.id.documentUUID] = doc
		}
		
		_idToDocumentsDictionary = idDictionary
		documentsDictionaryNeedUpdate = false
	}

	func rebuildTagsDictionary() {
		var idDictionary = [String: Tag]()
		
		for tag in tags ?? [Tag]() {
			idDictionary[tag.id] = tag
		}
		
		_idToTagsDictionary = idDictionary
		tagsDictionaryNeedUpdate = false
	}
	
	func deleteDocument(_ document: Document, updateCloudKit: Bool) {
		documents?.removeFirst(object: document)
		accountDocumentsDidChange()
		
		if updateCloudKit {
			deleteFromCloudKit(document)
		}

		for tag in document.tags ?? [Tag]() {
			deleteTag(tag)
		}

		document.delete()
	}
	
	func saveToCloudKit(_ document: Document) {
		guard let cloudKitManager = cloudKitManager, let zoneID = document.zoneID else { return }
		
		var requests = Set<CloudKitActionRequest>()
		requests.insert(CloudKitActionRequest(zoneID: zoneID, id: document.id))
		
		switch document {
		case .outline(let outline):
			if let rows = outline.keyedRows?.values {
				for row in rows {
					requests.insert(CloudKitActionRequest(zoneID: zoneID, id: row.entityID))
				}
			}
		}
		
		cloudKitManager.addRequests(requests)
	}
	
	func deleteFromCloudKit(_ document: Document) {
		guard let cloudKitManager = cloudKitManager, let zoneID = document.zoneID else { return }
		var requests = Set<CloudKitActionRequest>()
		requests.insert(CloudKitActionRequest(zoneID: zoneID, id: document.id))
		cloudKitManager.addRequests(requests)
	}
	
}

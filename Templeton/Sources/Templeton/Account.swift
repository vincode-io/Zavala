//
//  Account.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import os.log
import SWXMLHash
import ZipArchive

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
			return L10n.accountErrorScopedResource
		case .fileReadError:
			return L10n.accountErrorImportRead
		}
	}
}

public final class Account: NSObject, Identifiable, Codable {

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
		containers.append(RecentDocuments(account: self)
		)
		for tagDocuments in tags?
			.sorted(by: { $0.name < $1.name })
			.compactMap({ TagDocuments(account: self, tag: $0) }) ?? [TagDocuments]() {
			containers.append(tagDocuments)
		}
		
		return containers
	}
	
	enum CodingKeys: String, CodingKey {
		case type = "type"
		case isActive = "isActive"
		case tags = "tags"
		case documents = "documents"
	}
	
	var documents: [Document]?
	var folder: URL?
	
	private let operationQueue = OperationQueue()
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Account")

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
	
	public func importOPML(_ url: URL, tag: Tag?) throws -> Document {
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
		
		return importOPML(opmlData, tag: tag)
	}

	@discardableResult
	public func importOPML(_ opmlData: Data, tag: Tag?) -> Document {
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

		outline.importRows(outlineIndexers)

		if let expansionState = headIndexer["expansionState"].element?.text {
			outline.expansionState = expansionState
		}
		
		if let tag = tag, !outline.hasTag(tag) {
			outline.createTag(tag)
		}

		documents?.append(.outline(outline))
		accountDocumentsDidChange()
		outline.forceSave()
		return .outline(outline)
	}
	
	public func createOutline(title: String? = nil, tag: Tag? = nil) -> Document {
		let outline = Outline(parentID: id, title: title)
		if let tag = tag {
			outline.createTag(tag)
		}
		
		if documents == nil {
			documents = [Document]()
		}
		
		documents!.append(.outline(outline))
		accountDocumentsDidChange()
		return .outline(outline)
	}
	
	public func createDocument(_ document: Document) {
		document.reassignID(EntityID.document(id.accountID, document.id.documentUUID))
		if documents == nil {
			documents = [Document]()
		}
		documents!.append(document)
		accountDocumentsDidChange()
	}

	public func deleteDocument(_ document: Document) {
		documents?.removeFirst(object: document)
		accountDocumentsDidChange()
		document.delete()
	}
	
	public func findDocumentContainer(_ entityID: EntityID) -> DocumentContainer? {
		switch entityID {
		case .allDocuments:
			return AllDocuments(account: self)
		case .recentDocuments:
			return RecentDocuments(account: self)
		case .tagDocuments(_, let tagID):
			guard let tag = findTag(tagID: tagID) else { return nil }
			return TagDocuments(account: self, tag: tag)
		default:
			fatalError()
		}
	}
	
	public func findDocument(documentUUID: String) -> Document? {
		return idToDocumentsDictionary[documentUUID]
	}
	
	@discardableResult
	func createTag(name: String) -> Tag {
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
	
	func deleteTag(_ tag: Tag) {
		for doc in documents ?? [Document]() {
			if doc.hasTag(tag) {
				return
			}
		}
		
		tags?.removeFirst(object: tag)
		accountTagsDidChange()
	}
	
	func findTag(name: String) -> Tag? {
		return tags?.first(where: { $0.name == name })
	}
	
	func findTag(tagID: String) -> Tag? {
		return idToTagsDictionary[tagID]
	}
	
	func archive() -> URL? {
		guard let folder = folder else { return nil }
		
		var filename = type.name.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespaces)
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
		filename = "Zavala_\(filename)_\(formatter.string(from: Date())).zalarc"
		let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: self)
		
		fileCoordinator.coordinate(readingItemAt: folder, options: [], error: errorPointer, byAccessor: { readURL in
			SSZipArchive.createZipFile(atPath: tempFile.path, withContentsOfDirectory: readURL.path)
		})

		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "Account archive coordination failed: %@.", error.localizedDescription)
			return nil
		}

		return tempFile
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
}

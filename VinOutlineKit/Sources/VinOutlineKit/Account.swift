//
//  Account.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif
import CloudKit
import OrderedCollections
import VinXML
import VinCloudKit

public extension Notification.Name {
	static let AccountDidReload = Notification.Name(rawValue: "AccountDidReload")
	static let AccountMetadataDidChange = Notification.Name(rawValue: "AccountMetadataDidChange")
	static let AccountDocumentsDidChange = Notification.Name(rawValue: "AccountDocumentsDidChange")
	static let AccountTagsDidChange = Notification.Name(rawValue: "AccountTagsDidChange")
}

public enum AccountError: LocalizedError {
	case securityScopeError
	case fileReadError
	case opmlParserError
	case renameTagNameExistsError
	
	public var errorDescription: String? {
		switch self {
		case .fileReadError:
			return VinOutlineKitStringAssets.accountErrorImportRead
		case .opmlParserError:
			return VinOutlineKitStringAssets.accountErrorOPMLParse
		case .renameTagNameExistsError:
			return VinOutlineKitStringAssets.accountErrorRenameTagExists
		case .securityScopeError:
			return VinOutlineKitStringAssets.accountErrorScopedResource
		}
	}
}

@MainActor
public final class Account: Identifiable, Equatable {

	nonisolated public var id: EntityID {
		return EntityID.account(type.rawValue)
	}
	
	public var name: String {
		return type.name
	}
	
	nonisolated public let type: AccountType
	public var isActive: Bool
	
	public private(set) var tags: [Tag]?
	public private(set) var documents: [Document]?

	public var sharedDatabaseChangeToken: Data? {
		didSet {
			accountMetadataDidChange()
		}
	}

	public private(set) var zoneChangeTokens: [VCKChangeTokenKey: Data]?
	
	public var documentContainers: [DocumentContainer] {
		var containers = [DocumentContainer]()
		containers.append(AllDocuments(account: self))

		for tagDocuments in tags?
			.filter({ $0.level == 0 })
			.compactMap({ TagDocuments(account: self, tag: $0) }) ?? [TagDocuments]() {
			containers.append(tagDocuments)
		}
		
		return containers
	}
	
	public var cloudKitContainer: CKContainer? {
		return cloudKitManager?.container
	}
	
	var folder: URL {
		switch type {
		case .local:
			return accountManager!.localAccountFolder
		case .cloudKit:
			return accountManager!.cloudKitAccountFolder
		}
	}
	var cloudKitManager: CloudKitManager?
	
	private(set) weak var accountManager: AccountManager?

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

	init(accountManager: AccountManager, accountType: AccountType) {
		self.accountManager = accountManager
		self.type = accountType
		self.isActive = true
		self.documents = [Document]()
	}
	
	init(accountManager: AccountManager, coder: AccountCoder) {
		self.accountManager = accountManager
		
		self.type = coder.type
		self.isActive = coder.isActive
		
		if let tagCoders = coder.tags {
			self.tags = tagCoders.map { Tag(coder: $0) }
		}
		
		if let documentCoders = coder.documents {
			self.documents = documentCoders.map { Document(account: self, coder: $0)}
		}
		
		self.sharedDatabaseChangeToken = coder.sharedDatabaseChangeToken
		self.zoneChangeTokens = coder.zoneChangeTokens
	}
	
	func initializeCloudKit(errorHandler: ErrorHandler) {
		cloudKitManager = CloudKitManager(account: self, errorHandler: errorHandler, cloudKitAccountFolder: accountManager!.cloudKitAccountFolder)
		
		for document in documents ?? [] {
			cloudKitManager?.addSyncRecordIfNeeded(document: document)
		}
	}
	
	public func firstTimeCloudKitSetup() {
		Task {
			await cloudKitManager?.firstTimeSetup()
			await cloudKitManager?.sync()
		}
	}
	
	public func userDidAcceptCloudKitShareWith(_ shareMetadata: CKShare.Metadata) async {
		await cloudKitManager?.userDidAcceptCloudKitShareWith(shareMetadata)
	}

	public func generateCKShare(for document: Document) async throws -> CKShare {
		guard let cloudKitManager else { fatalError() }
		return try await cloudKitManager.generateCKShare(for: document)
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
	
	func store(changeToken: Data?, key: VCKChangeTokenKey) {
		if zoneChangeTokens == nil {
			zoneChangeTokens = [VCKChangeTokenKey: Data]()
		}
		zoneChangeTokens?[key] = changeToken
		accountMetadataDidChange()
	}
	
	public func importOPML(_ url: URL, tags: [Tag]?) async throws -> Document {
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
		
		return try await importOPML(opmlData, tags: tags)
	}

	@discardableResult
	public func importOPML(_ opmlData: Data, tags: [Tag]?, images: [String:  Data]? = nil) async throws -> Document {
		let opmlString = try convertOPMLAttributeNewlines(opmlData)
		
		guard let opmlNode = try? VinXML.XMLDocument(xml: opmlString, caseSensitive: false)?.root else {
			throw AccountError.opmlParserError
		}
		
		let headNode = opmlNode["head"]?.first
		let bodyNode = opmlNode["body"]?.first
		let rowNodes = bodyNode?["outline"]
		
		var title = headNode?["title"]?.first?.content
		if (title == nil || title!.isEmpty) && rowNodes?.count ?? 0 > 0 {
			title = rowNodes?.first?.attributes["text"]
		}
		if title == nil {
			title = VinOutlineKitStringAssets.noTitle
		}
		
		let outline = Outline(account: self, parentID: id, title: title)
		let document = Document.outline(outline)
		documents?.append(document)
		accountDocumentsDidChange()

		if let created = headNode?["dateCreated"]?.first?.content {
			outline.created = Date.dateFromRFC822(rfc822String: created)
		}
		if let updated = headNode?["dateModified"]?.first?.content {
			outline.updated = Date.dateFromRFC822(rfc822String: updated)
		}
		
		outline.ownerName = headNode?["ownerName"]?.first?.content
		outline.ownerEmail = headNode?["ownerEmail"]?.first?.content
		outline.ownerURL = headNode?["ownerID"]?.first?.content
		
		if let verticleScrollState = headNode?["vertScrollState"]?.first?.content {
			outline.verticleScrollState = Int(verticleScrollState)
		}
		
		if let numberingStyle = headNode?["numberingStyle"]?.first?.content {
			outline.numberingStyle = Outline.NumberingStyle(rawValue: numberingStyle)
		}

		if let automaticallyCreateLinks = headNode?["automaticallyCreateLinks"]?.first?.content {
			outline.automaticallyCreateLinks = automaticallyCreateLinks == "true" ? true : false
		}

		if let automaticallyChangeLinkTitles = headNode?["automaticallyChangeLinkTitles"]?.first?.content {
			outline.automaticallyChangeLinkTitles = automaticallyChangeLinkTitles == "true" ? true : false
		}

		if let checkSpellingWhileTyping = headNode?["checkSpellingWhileTyping"]?.first?.content {
			outline.checkSpellingWhileTyping = checkSpellingWhileTyping == "true" ? true : false
		}

		if let correctSpellingAutomatically = headNode?["correctSpellingAutomatically"]?.first?.content {
			outline.correctSpellingAutomatically = correctSpellingAutomatically == "true" ? true : false
		}

		if let tagNodes = headNode?["tags"]?.first?["tag"] {
			for tagNode in tagNodes {
				if let tagName = tagNode.content {
					let tag = createTag(name: tagName)
					outline.createTag(tag)
				}
			}
		}

		if let expansionState = headNode?["expansionState"]?.first?.content {
			outline.expansionState = expansionState
		}
		
		for tag in tags ?? [Tag]() {
			outline.createTag(tag)
		}

		if let rowNodes {
			outline.importRows(outline: outline, rowNodes: rowNodes, images: images)
		}
		
		outline.zoneID = cloudKitManager?.outlineZone.zoneID
		
		disambiguate(document: document)
		
		outline.updateAllLinkRelationships()
		
		fixAltLinks(excluding: outline)
		
		await outline.forceSave()
		saveToCloudKit(document)
		await outline.unload()

		return document
	}
	
	public func disambiguate(document: Document) {
		guard let documents else { return }
		
		if let lastCommon = documents.filter({ $0.title == document.title && $0.id != document.id }).sorted(by: { $0.disambiguator ?? 0 < $1.disambiguator ?? 0 }).last {
			document.update(disambiguator: (lastCommon.disambiguator ?? 1) + 1)
		}
	}
	
	public func createOutline(title: String? = nil, tags: [Tag]? = nil) -> Document {
		let outline = Outline(account: self, parentID: id, title: title)
		if documents == nil {
			documents = [Document]()
		}
		
		outline.zoneID = cloudKitManager?.outlineZone.zoneID
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
	
	func apply(_ update: CloudKitOutlineUpdate) async {
		guard !update.isDelete else {
			guard let document = findDocument(documentUUID: update.documentID.documentUUID) else { return }
			deleteDocument(document, updateCloudKit: false)
			return
		}
		
		if let document = findDocument(documentUUID: update.documentID.documentUUID) {
			let outline = document.outline!
			outline.load()
			outline.apply(update)
			await outline.forceSave()
			await outline.unload()
		} else {
			let outline = Outline(account: self, id: update.documentID)
			outline.zoneID = update.zoneID

			outline.apply(update)
			await outline.forceSave()
			await outline.unload()
			
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
		mutableDocument.zoneID = cloudKitManager?.outlineZone.zoneID
			
		documents!.append(mutableDocument)
		accountDocumentsDidChange()
		saveToCloudKit(mutableDocument)
	}

	public func deleteDocument(_ document: Document, updateCloudKit: Bool = true) {
		documents?.removeAll(where: { $0.id == document.id})
		accountDocumentsDidChange()
		
		if updateCloudKit {
			deleteFromCloudKit(document)
		}

		for tag in document.tags ?? [Tag]() {
			deleteTag(tag)
		}

		document.delete()
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
		let normalizedName = Tag.normalize(name: name)
		
		if let tag = tags?.first(where: { $0.name == normalizedName }) {
			return tag
		}
		
		let tag = Tag(name: normalizedName)
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
		
		// Recursively try to create any skipped tag levels
		if let tagParentName = tag.parentName {
			createTag(name: tagParentName)
		}
		
		tags?.append(tag)
		tags?.sort(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
		accountTagsDidChange()
		
		return tag
	}
	
	public func renameTag(_ tag: Tag, to newTagName: String) throws {
		guard let accountTags = tags else { return }

		let normalizedTagName = Tag.normalize(name: newTagName)

		if hasTag(name: normalizedTagName) {
			throw AccountError.renameTagNameExistsError
		}
		
		// Rename any decendents with this tag as a path
		for accountTag in accountTags {
			if accountTag.isDecendent(of: tag) {
				accountTag.renamePath(from: tag.name, to: normalizedTagName)
			}
		}

		let oldTagParentName = tag.parentName
		tag.name = normalizedTagName
		
		// Recursively try to create any skipped tag levels
		if let tagParentName = tag.parentName {
			createTag(name: tagParentName)
		}


		for doc in documents ?? [Document]() {
			if doc.hasTag(tag) {
				doc.requestCloudKitUpdateForSelf()
			}
		}
		
		// Recursively try to delete any unused tag levels
		if let oldTagParentName {
			deleteTag(name: oldTagParentName)
		}

		tags?.sort(by: { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending })
		accountTagsDidChange()
	}
	
	public func deleteTag(name: String) {
		guard let tag = tags?.first(where: { $0.name == name }) else {
			return
		}
		deleteTag(tag)
	}

	public func deleteTag(_ tag: Tag) {
		guard !isParentTag(tag) else { return }
		
		for doc in documents ?? [Document]() {
			if doc.hasTag(tag) {
				return
			}
		}
		
		tags?.removeFirst(object: tag)

		// Recursively try to delete any unused parent tag levels
		if let tagParentName = tag.parentName {
			deleteTag(name: tagParentName)
		}
		
		accountTagsDidChange()
	}
	
	public func forceDeleteTag(_ tag: Tag) {
		guard let accountTags = tags else { return }
		
		// We recursively force delete any decendent tags
		for accountTag in accountTags {
			if accountTag.isDecendent(of: tag) {
				forceDeleteTag(accountTag)
			}
		}

		for doc in documents ?? [Document]() {
			doc.deleteTag(tag)
		}

		tags?.removeFirst(object: tag)

		// Recursively try to delete any unused parent tag levels
		if let tagParentName = tag.parentName {
			deleteTag(name: tagParentName)
		}
		
		accountTagsDidChange()
	}
	
	public func findTag(name: String) -> Tag? {
		return tags?.first(where: { $0.name == name })
	}

	public func hasTag(name: String) -> Bool {
		return findTag(name: name) != nil
	}
	
	public func isParentTag(_ tag: Tag) -> Bool {
		guard let accountTags = tags else { return false }
		
		for accountTag in accountTags {
			if accountTag.isChild(of: tag) {
				return true
			}
		}
		
		return false
	}
	
	public func findDocument(shareRecordID: CKRecord.ID) -> Document? {
		return documents?.first(where: { $0.shareRecordID == shareRecordID })
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
	
	func toCoder() -> AccountCoder {
		var tagCoders = [TagCoder]()
		for tag in tags ?? [Tag]() {
			tagCoders.append(tag.toCoder())
		}
		
		var documentCoders = [DocumentCoder]()
		for document in documents ?? [Document]() {
			documentCoders.append(document.toCoder())
		}
		
		return AccountCoder(type: type,
							isActive: isActive,
							tags: tagCoders,
							documents: documentCoders,
							sharedDatabaseChangeToken: sharedDatabaseChangeToken,
							zoneChangeTokens: zoneChangeTokens)
	}
	
	func accountDidReload() {
		NotificationCenter.default.post(name: .AccountDidReload, object: self, userInfo: nil)
	}
	
	nonisolated public static func == (lhs: Account, rhs: Account) -> Bool {
		return lhs.id == rhs.id
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
	
	func saveToCloudKit(_ document: Document) {
		guard let cloudKitManager, let zoneID = document.zoneID else { return }
		
		var requests = OrderedSet<CloudKitActionRequest>()
		requests.append(CloudKitActionRequest(zoneID: zoneID, id: document.id))
		
		switch document {
		case .outline(let outline):
			for row in outline.allRows {
				requests.append(CloudKitActionRequest(zoneID: zoneID, id: row.entityID))
			}
			if let rowImages = outline.images?.values {
				for images in rowImages {
					for image in images {
						requests.append(CloudKitActionRequest(zoneID: zoneID, id: image.id))
					}
				}
			}
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
		
		cloudKitManager.addRequests(requests)
	}
	
	func deleteFromCloudKit(_ document: Document) {
		guard let cloudKitManager, let zoneID = document.zoneID else { return }
		cloudKitManager.addRequest(CloudKitActionRequest(zoneID: zoneID, id: document.id))
	}
	
	func convertOPMLAttributeNewlines(_ opmlData: Data) throws -> String {
		guard var opmlString = String(data: opmlData, encoding: .utf8),
			  let regEx = try? NSRegularExpression(pattern: "(text|_note)=\"([^\"]*)\"", options: []) else {
			throw AccountError.opmlParserError
		}
		
		for match in regEx.allMatches(in: opmlString) {
			for rangeIndex in 0..<match.numberOfRanges {
				let matchRange = match.range(at: rangeIndex)
				if let substringRange = Range(matchRange, in: opmlString) {
					opmlString = opmlString.replacingOccurrences(of: "\n", with: "&#10;", range: substringRange)
				}
			}
		}
		
		return opmlString
	}
}

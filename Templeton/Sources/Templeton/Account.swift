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
	public var documents: [Document]?
	
	public var documentContainers: [DocumentContainer] {
		var containers = [DocumentContainer]()
		containers.append(AccountDocuments(account: self))
		return containers
	}
	
	enum CodingKeys: String, CodingKey {
		case type = "type"
		case isActive = "isActive"
		case documents = "documents"
	}
	
	var folder: URL?
	private let operationQueue = OperationQueue()
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Account")

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
	
	public func importOPML(_ url: URL) throws -> Document {
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
		
		return importOPML(opmlData)
	}

	@discardableResult
	public func importOPML(_ opmlData: Data) -> Document {
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

		outline.importRows(outlineIndexers)

		if let expansionState = headIndexer["expansionState"].element?.text {
			outline.expansionState = expansionState
		}

		documents?.append(.outline(outline))
		accountDocumentsDidChange()
		outline.forceSave()
		return .outline(outline)
	}
	
	public func createOutline(title: String? = nil) -> Document {
		let outline = Outline(parentID: id, title: title)
		documents?.append(.outline(outline))
		accountDocumentsDidChange()
		return .outline(outline)
	}
	
	public func createDocument(_ document: Document) {
		document.reassignID(EntityID.document(id.accountID, document.id.documentUUID))
		documents?.append(document)
		accountDocumentsDidChange()
	}

	public func deleteDocument(_ document: Document) {
		documents?.removeFirst(object: document)
		accountDocumentsDidChange()
		document.delete()
	}
	
	public func findDocumentContainer(_ entityID: EntityID) -> DocumentContainer? {
		switch entityID {
		case .accountDocuments:
			return AccountDocuments(account: self)
		default:
			fatalError()
		}
	}
	
	public func findDocument(documentUUID: String) -> Document? {
		if let document = documents?.first(where: { $0.id.documentUUID == documentUUID }) {
			return document
		}
		return nil
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

extension Account {

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

}

private extension Account {
	
	func accountMetadataDidChange() {
		NotificationCenter.default.post(name: .AccountMetadataDidChange, object: self, userInfo: nil)
	}
	
	func accountDocumentsDidChange() {
		NotificationCenter.default.post(name: .AccountDocumentsDidChange, object: self, userInfo: nil)
	}
	
}

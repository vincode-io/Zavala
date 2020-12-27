//
//  Folder.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import RSCore
import SWXMLHash

public extension Notification.Name {
	static let FolderMetaDataDidChange = Notification.Name(rawValue: "FolderMetaDataDidChange")
	static let FolderDocumentsDidChange = Notification.Name(rawValue: "FolderDocumentsDidChange")
	static let FolderDidDelete = Notification.Name(rawValue: "FolderDidDelete")
}

public enum FolderError: LocalizedError {
	case securityScopeError
	case fileReadError
	
	public var errorDescription: String? {
		switch self {
		case .securityScopeError:
			return L10n.folderErrorScopedResource
		case .fileReadError:
			return L10n.folderErrorImportRead
		}
	}
}

public final class Folder: Identifiable, Equatable, Codable, DocumentContainer {
	
	public var id: EntityID
	public var name: String?
	public var image: RSImage? {
		return RSImage(systemName: "folder")
	}
	
	public var documents: [Document]?

	public var sortedDocuments: [Document] {
		return Self.sortByTitle(documents ?? [Document]())
	}

	public var account: Account? {
		return AccountManager.shared.findAccount(accountID: id.accountID)
	}
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
		case documents = "documents"
	}
	
	init(parentID: EntityID, name: String) {
		self.id = EntityID.folder(parentID.accountID, UUID().uuidString)
		self.name = name
		self.documents = [Document]()
	}

	func folderDidDelete() {
		NotificationCenter.default.post(name: .FolderDidDelete, object: self, userInfo: nil)
	}
	
	public func update(name: String) {
		self.name = name
		folderMetaDataDidChange()
	}
	
	public func importOPML(_ url: URL) throws -> Document {
		guard url.startAccessingSecurityScopedResource() else { throw FolderError.securityScopeError }
		defer {
			url.stopAccessingSecurityScopedResource()
		}
		
		var fileData: Data?
		var fileError: NSError? = nil
		NSFileCoordinator().coordinate(readingItemAt: url, error: &fileError) { (url) in
			fileData = try? Data(contentsOf: url)
		}
		
		guard fileError == nil else { throw fileError! }
		guard let opmlData = fileData else { throw FolderError.fileReadError }
		
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
		folderDocumentsDidChange()
		outline.forceSave()
		return .outline(outline)
	}
	
	public func createOutline(title: String? = nil) -> Document {
		let outline = Outline(parentID: id, title: title)
		documents?.append(.outline(outline))
		folderDocumentsDidChange()
		return .outline(outline)
	}
	
	public func createDocument(_ document: Document) {
		document.reassignID(EntityID.document(id.accountID, id.folderUUID, document.id.documentUUID))
		documents?.append(document)
		folderDocumentsDidChange()
	}
	
	public func deleteDocument(_ document: Document) {
		documents?.removeFirst(object: document)
		folderDocumentsDidChange()
		document.delete()
	}
	
	public static func == (lhs: Folder, rhs: Folder) -> Bool {
		return lhs.id == rhs.id
	}
}

extension Folder {
	
	func findDocument(documentUUID: String) -> Document? {
		if let document = documents?.first(where: { $0.id.documentUUID == documentUUID }) {
			return document
		}
		return nil
	}

}

private extension Folder {
	
	func folderMetaDataDidChange() {
		NotificationCenter.default.post(name: .FolderMetaDataDidChange, object: self, userInfo: nil)
	}
	
	func folderDocumentsDidChange() {
		NotificationCenter.default.post(name: .FolderDocumentsDidChange, object: self, userInfo: nil)
	}
	
}

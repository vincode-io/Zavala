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
	static let FolderOutlinesDidChange = Notification.Name(rawValue: "FolderOutlinesDidChange")
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

public final class Folder: Identifiable, Equatable, Codable, OutlineProvider {
	
	public var id: EntityID
	public var name: String?
	public var image: RSImage? {
		return RSImage(systemName: "folder")
	}
	
	public var outlines: [Outline]?

	public var sortedOutlines: [Outline] {
		return Self.sortByUpdate(outlines ?? [Outline]())
	}

	public var account: Account? {
		return AccountManager.shared.findAccount(accountID: id.accountID)
	}
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
		case outlines = "outlines"
	}
	
	init(parentID: EntityID, name: String) {
		self.id = EntityID.folder(parentID.accountID, UUID().uuidString)
		self.name = name
		self.outlines = [Outline]()
	}

	func folderDidDelete() {
		NotificationCenter.default.post(name: .FolderDidDelete, object: self, userInfo: nil)
	}
	
	public func update(name: String) {
		self.name = name
		folderMetaDataDidChange()
	}
	
	public func importOPML(_ url: URL) throws -> Outline {
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
		
		let outline = createOutline(name: title!)
		outline.importOPML(outlineIndexers)
		outline.forceSave()
		return outline
	}
	
	public func createOutline(name: String) -> Outline {
		let outline = Outline(parentID: id, title: name)
		outlines?.append(outline)
		folderOutlinesDidChange()
		return outline
	}
	
	public func deleteOutline(_ outline: Outline) {
		outlines = outlines?.filter({ $0 != outline })
		folderOutlinesDidChange()
		outline.delete()
	}
	
	public func moveOutline(_ outline: Outline, from: Folder, to: Folder) {
	}
	
	public static func == (lhs: Folder, rhs: Folder) -> Bool {
		return lhs.id == rhs.id
	}
}

extension Folder {
	
	func findOutline(outlineUUID: String) -> Outline? {
		return outlines?.first(where: { $0.id.outlineUUID == outlineUUID })
	}

}

private extension Folder {
	
	func folderMetaDataDidChange() {
		NotificationCenter.default.post(name: .FolderMetaDataDidChange, object: self, userInfo: nil)
	}
	
	func folderOutlinesDidChange() {
		NotificationCenter.default.post(name: .FolderOutlinesDidChange, object: self, userInfo: nil)
	}
	
}

//
//  Folder.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import RSCore

public extension Notification.Name {
	static let FolderMetaDataDidChange = Notification.Name(rawValue: "FolderMetaDataDidChange")
	static let FolderOutlinesDidChange = Notification.Name(rawValue: "FolderOutlinesDidChange")
	static let FolderDidDelete = Notification.Name(rawValue: "FolderDidDelete")
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
	
	public func createOutline(name: String) -> Outline {
		let outline = Outline(parentID: id, name: name)
		outlines?.append(outline)
		folderOutlinesDidChange()
		return outline
	}
	
	public func deleteOutline(_ outline: Outline) {
		outlines = outlines?.filter({ $0 != outline })
		folderOutlinesDidChange()
		outline.outlineDidDelete()
	}
	
	public func moveOutline(_ outline: Outline, from: Folder, to: Folder) {
	}
	
	public static func == (lhs: Folder, rhs: Folder) -> Bool {
		return lhs.id == rhs.id
	}
}

extension Folder {
	
	func findOutline(outlineID: String) -> Outline? {
		return outlines?.first(where: { $0.id.outlineID == outlineID })
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

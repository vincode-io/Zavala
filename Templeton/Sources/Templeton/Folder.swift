//
//  Folder.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import RSCore

public extension Notification.Name {
	static let FolderDidChange = Notification.Name(rawValue: "FolderDidChange")
}

public final class Folder: Identifiable, Equatable, Codable, OutlineProvider {
	
	public var id: EntityID
	public var name: String?
	public var image: RSImage? {
		return RSImage(systemName: "folder")
	}
	
	public let isSmartProvider = false
	public var outlines: [Outline]?

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
	
	public static func == (lhs: Folder, rhs: Folder) -> Bool {
		return lhs.id == rhs.id
	}
}

extension Folder {
	
	func addOutline(_ outline: Outline) {
		outlines?.append(outline)
		outlinesDidChange()
	}
	
	func removeOutline(_ outline: Outline) {
		outlines = outlines?.filter({ $0 != outline })
		outlinesDidChange()
	}
	
	func findOutline(outlineID: String) -> Outline? {
		return outlines?.first(where: { $0.id?.outlineID == outlineID })
	}

}

private extension Folder {
	
	func folderDidChange() {
		NotificationCenter.default.post(name: .FolderDidChange, object: self, userInfo: nil)
	}
	
}

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

	public func createOutline(name: String, completion: @escaping (Result<Outline, Error>) -> Void) {
		func createOutline() {
			let outline = Outline(parentID: id, name: name)
			outlines?.append(outline)
			outlinesDidChange()
			completion(.success(outline))
		}
		
		if account?.type == .cloudKit {
			createOutline()
		} else {
			createOutline()
		}
	}
	
	public func removeOutline(_ outline: Outline, completion: @escaping (Result<Void, Error>) -> Void) {
		func removeOutline() {
			outlines = outlines?.filter({ $0 != outline })
			outlinesDidChange()
			completion(.success(()))
		}
		
		if account?.type == .cloudKit {
			removeOutline()
		} else {
			removeOutline()
		}
	}
	
	public func moveOutline(_ outline: Outline, from: Folder, to: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
	}
	
	public func renameOutline(_ outline: Outline, to name: String, completion: @escaping (Result<Void, Error>) -> Void) {
		func renameOutline() {
			outline.name = name
			outlinesDidChange()
			completion(.success(()))
		}
		
		if account?.type == .cloudKit {
			renameOutline()
		} else {
			renameOutline()
		}
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
	
	func folderDidChange() {
		NotificationCenter.default.post(name: .FolderDidChange, object: self, userInfo: nil)
	}
	
}

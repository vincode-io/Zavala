//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public extension Notification.Name {
	static let OutlineMetaDataDidChange = Notification.Name(rawValue: "OutlineMetaDataDidChange")
	static let OutlineBodyDidChange = Notification.Name(rawValue: "OutlineBodyDidChange")
	static let OutlineDidDelete = Notification.Name(rawValue: "OutlineDidDelete")
}

public final class Outline: Identifiable, Equatable, Codable {
	
	public var id: EntityID
	public var name: String?
	public var isFavorite: Bool?
	public var created: Date?
	public var updated: Date?
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
		case isFavorite = "isFavorite"
		case created = "created"
		case updated = "updated"
	}
	
	public var account: Account? {
		return AccountManager.shared.findAccount(accountID: id.accountID)
	}
	
	public var folder: Folder? {
		let folderID = EntityID.folder(id.accountID, id.folderID)
		return AccountManager.shared.findFolder(folderID)
	}

	init(parentID: EntityID, name: String) {
		self.id = EntityID.outline(parentID.accountID, parentID.folderID, UUID().uuidString)
		self.name = name
		self.created = Date()
		self.updated = Date()
	}

	func outlineDidDelete() {
		NotificationCenter.default.post(name: .OutlineDidDelete, object: self, userInfo: nil)
	}

	public func toggleFavorite(completion: @escaping (Result<Void, Error>) -> Void) {
		func toggleFavorite() {
			isFavorite = !(isFavorite ?? false)
			outlineMetaDataDidChange()
			completion(.success(()))
		}
		
		if account?.type == .cloudKit {
			toggleFavorite()
		} else {
			toggleFavorite()
		}
	}
	
	public func update(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
		func update() {
			self.name = name
			self.updated = Date()
			outlineMetaDataDidChange()
			completion(.success(()))
		}
		
		if account?.type == .cloudKit {
			update()
		} else {
			update()
		}
	}
	
	public static func == (lhs: Outline, rhs: Outline) -> Bool {
		return lhs.id == rhs.id
	}
	
}

private extension Outline {
	
	func outlineMetaDataDidChange() {
		NotificationCenter.default.post(name: .OutlineMetaDataDidChange, object: self, userInfo: nil)
	}
	
}

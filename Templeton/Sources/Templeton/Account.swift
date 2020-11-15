//
//  Account.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public extension Notification.Name {
	static let AccountFoldersDidChange = Notification.Name(rawValue: "AccountFoldersDidChange")
}

public final class Account: Identifiable, Equatable, Codable {

	public var id: EntityID {
		return EntityID.account(type.rawValue)
	}
	
	public var name: String {
		return type.name
	}
	
	public var type: AccountType
	public var isActive: Bool
	public var folders: [Folder]?
	
	public var sortedFolders: [Folder] {
		guard let folders = folders else { return [Folder]() }
		return folders.sorted(by: { $0.name ?? "" < $1.name ?? "" })
	}
	
	public var outlines: [Outline] {
		return folders?.reduce(into: [Outline]()) { $0.append(contentsOf: $1.outlines ?? [Outline]()) } ?? [Outline]()
	}
	
	enum CodingKeys: String, CodingKey {
		case type = "type"
		case isActive = "isActive"
		case folders = "folders"
	}

	init(accountType: AccountType) {
		self.type = accountType
		self.isActive = true
		self.folders = [Folder]()
	}
	
	public func createFolder(_ name: String, completion: @escaping (Result<Folder, Error>) -> Void) {
		func createFolder() {
			let folder = Folder(parentID: id, name: name)
			folders?.append(folder)
			accountDidChange()
			completion(.success(folder))
		}
		
		if type == .cloudKit {
			createFolder()
		} else {
			createFolder()
		}
	}
	
	public func removeFolder(_ folder: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
		guard let folders = folders else {
			completion(.success(()))
			return
		}
		
		func removeFolder() {
			self.folders = folders.filter { $0 != folder }
			accountDidChange()
			folder.folderDidDelete()
			completion(.success(()))
		}
		
		if type == .cloudKit {
			removeFolder()
		} else {
			removeFolder()
		}
	}
	
	public static func == (lhs: Account, rhs: Account) -> Bool {
		return lhs.id == rhs.id
	}
	
}

extension Account {

	func findFolder(folderID: String) -> Folder? {
		return folders?.first(where: { $0.id.folderID == folderID })
	}

}

private extension Account {
	
	func accountDidChange() {
		NotificationCenter.default.post(name: .AccountFoldersDidChange, object: self, userInfo: nil)
	}
	
}

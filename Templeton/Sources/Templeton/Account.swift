//
//  Account.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public extension Notification.Name {
	static let AccountDidChange = Notification.Name(rawValue: "AccountDidChange")
}

public final class Account: Identifiable, Codable {

	public var id: Int {
		type.rawValue
	}
	
	public var type: AccountType
	public var isActive: Bool
	public var folders: [Folder]?
	
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
	
	public func addOutline(_ outline: Outline, to folder: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
	}

	public func createOutline(name: String, folder: Folder, completion: @escaping (Result<Outline, Error>) -> Void) {
	}
	
	public func removeOutline(_ outline: Outline, from folder: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
	}
	
	public func moveOutline(_ outline: Outline, from: Folder, to: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
	}
	
	public func renameOutline(_ outline: Outline, to name: String, completion: @escaping (Result<Void, Error>) -> Void) {
	}
	
	public func restoreOutline(_ outline: Outline, folder: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
	}
	
	public func createFolder(_ name: String, completion: @escaping (Result<Folder, Error>) -> Void) {
		let folder = Folder(name: name)
		folders?.append(folder)
		accountDidChange()
	}
	
	public func removeFolder(_ folder: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
		guard let folders = folders else {
			completion(.success(()))
			return
		}
		self.folders = folders.filter { $0 != folder }
		accountDidChange()
	}
	
	public func renameFolder(_ folder: Folder, to name: String, completion: @escaping (Result<Void, Error>) -> Void) {
		folder.name = name
		accountDidChange()
	}

	public func restoreFolder(_ folder: Folder, completion: @escaping (Result<Void, Error>) -> Void) {
		folders?.append(folder)
		accountDidChange()
	}
	
}

private extension Account {
	func accountDidChange() {
		NotificationCenter.default.post(name: .AccountDidChange, object: self, userInfo: nil)
	}
}

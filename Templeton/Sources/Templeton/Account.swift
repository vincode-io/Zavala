//
//  Account.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import os.log
import ZipArchive

public extension Notification.Name {
	static let AccountDidInitialize = Notification.Name(rawValue: "AccountDidInitialize")
	static let AccountMetadataDidChange = Notification.Name(rawValue: "AccountMetadataDidChange")
	static let AccountFoldersDidChange = Notification.Name(rawValue: "AccountFoldersDidChange")
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
	
	var folder: URL?
	private let operationQueue = OperationQueue()
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Account")

	init(accountType: AccountType) {
		self.type = accountType
		self.isActive = true
		self.folders = [Folder]()
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
	
	public func createFolder(_ name: String) -> Folder {
		let folder = Folder(parentID: id, name: name)
		folders?.append(folder)
		accountFoldersDidChange()
		return folder
	}
	
	public func deleteFolder(_ folder: Folder) {
		guard let folders = folders else {
			return
		}
		
		self.folders = folders.filter { $0 != folder }
		accountFoldersDidChange()
		folder.folderDidDelete()
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

	func findFolder(folderUUID: String) -> Folder? {
		return folders?.first(where: { $0.id.folderUUID == folderUUID })
	}
	
	func archive() -> URL? {
		guard let folder = folder else { return nil }
		
		var filename = type.name.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespaces)
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
		filename = "Zavala_\(filename)_\(formatter.string(from: Date())).manarc"
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
	
	func accountFoldersDidChange() {
		NotificationCenter.default.post(name: .AccountFoldersDidChange, object: self, userInfo: nil)
	}
	
}

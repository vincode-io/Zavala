//
//  AccountManager.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import os.log
import ZipArchive

public enum AccountManagerError: LocalizedError {
	case readArchiveError
	public var errorDescription: String? {
		return L10n.checkArchiveError
	}
}

public final class AccountManager {
	
	public static var shared: AccountManager!
	
	public var localAccount: Account? {
		guard let local = accountsDictionary[AccountType.local.rawValue], local.isActive else { return nil }
		return local
	}

	public var allOutlineProvider: DocumentContainer {
		return LazyDocumentContainer(id: .all, callback: { [weak self] in
			return LazyDocumentContainer.sortByTitle(self?.outlines ?? [Document]())
		})
	}
	
	public var recentsOutlineProvider: DocumentContainer {
		return LazyDocumentContainer(id: .recents, callback: { [weak self] in
			let sorted = LazyDocumentContainer.sortByUpdate(self?.outlines ?? [Document]())
			return Array(sorted.prefix(10))
		})
	}
	
	public var favoritesOutlineProvider: DocumentContainer {
		return LazyDocumentContainer(id: .favorites, callback: { [weak self] in
			let favorites = self?.outlines.filter { $0.isFavorite ?? false }
			return LazyDocumentContainer.sortByTitle(favorites ?? [Document]())
		})
	}
	
	public var accounts: [Account] {
		return Array(accountsDictionary.values)
	}

	public var sortedAccounts: [Account] {
		return sort(accounts)
	}

	public var activeAccounts: [Account] {
		return Array(accountsDictionary.values.filter { $0.isActive })
	}

	public var sortedActiveAccounts: [Account] {
		return sort(activeAccounts)
	}
	
	var accountsDictionary = [Int: Account]()

	var accountsFolder: URL
	var localAccountFolder: URL
	var localAccountFile: URL
	var cloudKitAccountFolder: URL
	var cloudKitAccountFile: URL

	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "AccountManager")

	private var accountFiles = [Int: AccountFile]()
	
	private var outlines: [Document] {
		return activeAccounts.reduce(into: [Document]()) { $0.append(contentsOf: $1.outlines ) }
	}
	
	public init(accountsFolderPath: String) {
		self.accountsFolder = URL(fileURLWithPath: accountsFolderPath, isDirectory: true)
		self.localAccountFolder = accountsFolder.appendingPathComponent(AccountType.local.folderName)
		self.localAccountFile = localAccountFolder.appendingPathComponent(AccountFile.filenameComponent)
		self.cloudKitAccountFolder = accountsFolder.appendingPathComponent(AccountType.cloudKit.folderName)
		self.cloudKitAccountFile = cloudKitAccountFolder.appendingPathComponent(AccountFile.filenameComponent)
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountFoldersDidChange(_:)), name: .AccountFoldersDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(folderMetadataDidChange(_:)), name: .FolderMetaDataDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(folderOutlinesDidChange(_:)), name: .FolderOutlinesDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(documentTitleDidChange(_:)), name: .DocumentTitleDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineMetadataDidChange(_:)), name: .OutlineMetaDataDidChange, object: nil)

		// The local account must always exist, even if it's empty.
		if FileManager.default.fileExists(atPath: localAccountFile.path) {
			initializeFile(accountType: .local)
		} else {
			do {
				try FileManager.default.createDirectory(atPath: localAccountFolder.path, withIntermediateDirectories: true, attributes: nil)
			} catch {
				assertionFailure("Could not create folder for local account.")
				abort()
			}
			
			let localAccount = Account(accountType: .local)
			accountsDictionary[AccountType.local.rawValue] = localAccount
			initializeFile(accountType: .local)
			let _ = localAccount.createFolder("Outlines")
		}
		
		if FileManager.default.fileExists(atPath: cloudKitAccountFile.path) {
			initializeFile(accountType: .cloudKit)
		}
	}

	// MARK: API
	public func findAccount(accountType: AccountType) -> Account? {
		return accountsDictionary[accountType.rawValue]
	}

	public func findAccount(accountID: Int) -> Account? {
		return accountsDictionary[accountID]
	}
	
	public func findOutlineProvider(_ entityID: EntityID) -> DocumentContainer? {
		switch entityID {
		case .all:
			return allOutlineProvider
		case .favorites:
			return favoritesOutlineProvider
		case .recents:
			return recentsOutlineProvider
		case .folder:
			return findFolder(entityID)
		default:
			fatalError()
		}
	}
	
	public func findFolder(_ entityID: EntityID) -> Folder? {
		if case .folder(let accountID, let folderUUID) = entityID, let account = accountsDictionary[accountID] {
			return account.findFolder(folderUUID: folderUUID)
		}
		return nil
	}
	
	public func findDocument(_ entityID: EntityID) -> Document? {
		if case .document(let accountID, let folderUUID, let documentUUID) = entityID,
		   let account = accountsDictionary[accountID],
		   let folder = account.findFolder(folderUUID: folderUUID) {
			return folder.findDocument(documentUUID: documentUUID)
		}
		return nil
	}
	
	public func save() {
		accountFiles.values.forEach { $0.save() }
		outlines.forEach { $0.save() }
	}
	
	public func unpackArchive(_ archiveURL: URL) throws -> (AccountType, URL) {
		let restoreFolder = accountsFolder.appendingPathComponent("restore")
		
		guard SSZipArchive.unzipFile(atPath: archiveURL.path, toDestination: restoreFolder.path) else {
			os_log(.error, log: log, "Archive unzip failed.")
			throw AccountManagerError.readArchiveError
		}
		
		let accountFile = restoreFolder.appendingPathComponent(AccountFile.filenameComponent)
		let decoder = PropertyListDecoder()

		do {
			let accountData = try Data(contentsOf: accountFile)
			let account = try decoder.decode(Account.self, from: accountData)
			return (account.type, restoreFolder)
		} catch {
			os_log(.error, log: log, "Archive account read deserialization failed: %@.", error.localizedDescription)
			throw AccountManagerError.readArchiveError
		}
	}
	
	public func cleanUpArchive(unpackURL: URL) {
		try? FileManager.default.removeItem(at: unpackURL)
	}
	
	public func restoreArchive(accountType: AccountType, unpackURL: URL) {
		var account = accountsDictionary[accountType.rawValue]
		account?.deactivate()
		accountFiles.removeValue(forKey: accountType.rawValue)
		accountsDictionary.removeValue(forKey: accountType.rawValue)
		account = nil
		
		let accountFolder: URL
		if accountType == .local {
			accountFolder = localAccountFolder
		} else {
			accountFolder = cloudKitAccountFile
		}
		
		try? FileManager.default.removeItem(at: accountFolder)
		try? FileManager.default.moveItem(at: unpackURL, to: accountFolder)
		
		initializeFile(accountType: accountType)
		account = accountsDictionary[accountType.rawValue]
		account?.accountDidInitialize()
	}
	
	public func archiveAccount(type: AccountType) -> URL? {
		return accountsDictionary[type.rawValue]?.archive()
	}
	
}

// MARK: Private

private extension AccountManager {
	
	// MARK: Notifications
	
	@objc func accountFoldersDidChange(_ note: Notification) {
		let account = note.object as! Account
		markAsDirty(account)
	}

	@objc func folderMetadataDidChange(_ note: Notification) {
		guard let account = (note.object as? Folder)?.account else { return }
		markAsDirty(account)
	}

	@objc func folderOutlinesDidChange(_ note: Notification) {
		guard let account = (note.object as? Folder)?.account else { return }
		markAsDirty(account)
	}
	
	@objc func documentTitleDidChange(_ note: Notification) {
		guard let account = (note.object as? Outline)?.account else { return }
		markAsDirty(account)
	}
	
	@objc func outlineMetadataDidChange(_ note: Notification) {
		guard let account = (note.object as? Outline)?.account else { return }
		markAsDirty(account)
	}

	// MARK: Helpers
	
	func initializeFile(accountType: AccountType) {
		let file: URL
		if accountType == .local {
			file = localAccountFile
		} else {
			file = cloudKitAccountFile
		}
		
		let managedFile = AccountFile(fileURL: file, accountType: accountType, accountManager: self)
		managedFile.load()
		accountFiles[accountType.rawValue] = managedFile
	}

	func sort(_ accounts: [Account]) -> [Account] {
		return accounts.sorted { (account1, account2) -> Bool in
			if account1.type == .local {
				return true
			}
			if account2.type == .local {
				return false
			}
			return (account1.name as NSString).localizedStandardCompare(account2.name) == .orderedAscending
		}
	}
	
	func markAsDirty(_ account: Account) {
		let accountFile = accountFiles[account.type.rawValue]!
		accountFile.markAsDirty()
	}
	
}

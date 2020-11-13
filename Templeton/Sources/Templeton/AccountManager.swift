//
//  AccountManager.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class AccountManager {
	public static var shared: AccountManager!
	
	public var localAccount: Account? {
		guard let local = accountsDictionary[AccountType.local.rawValue], local.isActive else { return nil }
		return local
	}

	public var allOutlineProvider: OutlineProvider {
		return LazyOutlineProvider(id: .all, callback: { return [Outline]() })
	}
	
	public var recentsOutlineProvider: OutlineProvider {
		return LazyOutlineProvider(id: .recents, callback: { return [Outline]() })
	}
	
	public var favoritesOutlineProvider: OutlineProvider {
		return LazyOutlineProvider(id: .favorites, callback: { return [Outline]() })
	}
	
	private var accountsFolder: URL
	private var accountFiles = [Int: AccountFile]()
	
	var accountsDictionary = [Int: Account]()

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
	
	public init(accountsFolderPath: String) {
		self.accountsFolder = URL(fileURLWithPath: accountsFolderPath, isDirectory: true)

		NotificationCenter.default.addObserver(self, selector: #selector(accountFoldersDidChange(_:)), name: .AccountFoldersDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(folderMetadataDidChange(_:)), name: .FolderMetaDataDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(folderOutlinesDidChange(_:)), name: .FolderOutlinesDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineMetadataDidChange(_:)), name: .OutlinesDidChange, object: nil)

		// The local account must always exist, even if it's empty.
		let localAccountFolder = accountsFolder.appendingPathComponent(AccountType.local.folderNmae)
		let localAccountFile = localAccountFolder.appendingPathComponent(AccountFile.filenameComponent)
		
		if FileManager.default.fileExists(atPath: localAccountFile.path) {
			initializeFile(file: localAccountFile, accountType: .local)
		} else {
			do {
				try FileManager.default.createDirectory(atPath: localAccountFolder.path, withIntermediateDirectories: true, attributes: nil)
			} catch {
				assertionFailure("Could not create folder for local account.")
				abort()
			}
			
			let localAccount = Account(accountType: .local)
			accountsDictionary[AccountType.local.rawValue] = localAccount
			initializeFile(file: localAccountFile, accountType: .local)
			localAccount.createFolder("Outlines") { _ in }
		}
		
		let cloudKitAccountFolder = accountsFolder.appendingPathComponent(AccountType.cloudKit.folderNmae)
		let cloudKitAccountFile = cloudKitAccountFolder.appendingPathComponent(AccountFile.filenameComponent)
		
		if FileManager.default.fileExists(atPath: cloudKitAccountFile.path) {
			initializeFile(file: cloudKitAccountFile, accountType: .cloudKit)
		}
	}

	// MARK: API
	public func findAccount(accountID: Int) -> Account? {
		return accountsDictionary[accountID]
	}
	
	public func findOutlineProvider(_ entityID: EntityID) -> OutlineProvider? {
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
		if case .folder(let accountID, let folderID) = entityID, let account = accountsDictionary[accountID] {
			return account.findFolder(folderID: folderID)
		}
		return nil
	}
	
	public func findOutline(_ entityID: EntityID) -> Outline? {
		if case .outline(let accountID, let folderID, let outlineID) = entityID,
		   let account = accountsDictionary[accountID],
		   let folder = account.findFolder(folderID: folderID) {
			return folder.findOutline(outlineID: outlineID)
		}
		return nil
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
	
	@objc func outlineMetadataDidChange(_ note: Notification) {
		guard let account = (note.object as? Outline)?.account else { return }
		markAsDirty(account)
	}

	// MARK: Helpers
	
	func initializeFile(file: URL, accountType: AccountType) {
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

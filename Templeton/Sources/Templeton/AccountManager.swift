//
//  AccountManager.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class AccountManager {
	public static var shared: AccountManager!

	private var accountsDictionary = [AccountType: Account]()
	private var accountsFolder: URL
	private var accountFiles = [AccountType: AccountFile]()
	
	public var accounts: [Account] {
		return Array(accountsDictionary.values)
	}

	public var sortedAccounts: [Account] {
		return sort(accounts)
	}

	public var activeAccounts: [Account] {
		assert(Thread.isMainThread)
		return Array(accountsDictionary.values.filter { $0.isActive })
	}

	public var sortedActiveAccounts: [Account] {
		return sort(activeAccounts)
	}
	
	public init(accountsFolderPath: String) {
		self.accountsFolder = URL(fileURLWithPath: accountsFolderPath, isDirectory: true)

		NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange(_:)), name: .AccountDidChange, object: nil)
		
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
			accountsDictionary[.local] = localAccount
			initializeFile(file: localAccountFile, accountType: .local)
			localAccount.createFolder("Outlines") { _ in }
		}
		
		let cloudKitAccountFolder = accountsFolder.appendingPathComponent(AccountType.cloudKit.folderNmae)
		let cloudKitAccountFile = cloudKitAccountFolder.appendingPathComponent(AccountFile.filenameComponent)
		
		if FileManager.default.fileExists(atPath: cloudKitAccountFile.path) {
			initializeFile(file: cloudKitAccountFile, accountType: .cloudKit)
		}
	}

}

// MARK: Private

private extension AccountManager {
	
	// MARK: Notifications
	
	@objc func accountDidChange(_ note: Notification) {
		let account = note.object as! Account
		let accountFile = accountFiles[account.type]!
		accountFile.markAsDirty()
	}
	
	// MARK: Helpers
	
	func initializeFile(file: URL, accountType: AccountType) {
		let managedFile = AccountFile(fileURL: file, accountType: accountType)
		managedFile.load()
		accountFiles[accountType] = managedFile
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
	
}

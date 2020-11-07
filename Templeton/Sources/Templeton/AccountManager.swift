//
//  AccountManager.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class AccountManager {
	public static var shared: AccountManager!

	var accounts = [AccountType: Account]()

	private var accountsFolder: URL
	private var accountFiles = [AccountType: AccountFile]()
	
	public init(accountsFolderPath: String) {
		self.accountsFolder = URL(fileURLWithPath: accountsFolderPath, isDirectory: true)

		// The local account must always exist, even if it's empty.
		let localAccountFolder = accountsFolder.appendingPathComponent(AccountType.local.folderNmae)
		let localAccountFile = localAccountFolder.appendingPathComponent(AccountFile.filenameComponent)
		
		if FileManager.default.fileExists(atPath: localAccountFile.path) {
			initializeFile(file: localAccountFile, accountType: .local)
		} else {
			do {
				try FileManager.default.createDirectory(atPath: localAccountFolder.path, withIntermediateDirectories: true, attributes: nil)
			}
			catch {
				assertionFailure("Could not create folder for OnMyMac account.")
				abort()
			}
			
			accounts[.local] = Account(accountType: .local)
			initializeFile(file: localAccountFile, accountType: .local)
		}
		
		let cloudKitAccountFolder = accountsFolder.appendingPathComponent(AccountType.cloudKit.folderNmae)
		let cloudKitAccountFile = cloudKitAccountFolder.appendingPathComponent(AccountFile.filenameComponent)
		
		if FileManager.default.fileExists(atPath: cloudKitAccountFile.path) {
			initializeFile(file: cloudKitAccountFile, accountType: .cloudKit)
		}
	}

}

private extension AccountManager {
	
	func initializeFile(file: URL, accountType: AccountType) {
		let managedFile = AccountFile(fileURL: file, accountType: accountType)
		managedFile.load()
		accountFiles[accountType] = managedFile
	}
	
}

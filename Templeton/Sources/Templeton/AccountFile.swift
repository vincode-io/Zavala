//
//  AccountFile.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import os.log
import RSCore

final class AccountFile {
	
	public static let filenameComponent = "account.json"
	
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "accountFile")

	private weak var accountManager: AccountManager?
	private let fileURL: URL
	private let accountType: AccountType
	private lazy var managedFile = ManagedResourceFile(fileURL: fileURL, load: loadCallback, save: saveCallback)
	
	init(fileURL: URL, accountType: AccountType, accountManager: AccountManager) {
		self.fileURL = fileURL
		self.accountType = accountType
		self.accountManager = accountManager
	}
	
	func markAsDirty() {
		managedFile.markAsDirty()
	}
	
	func load() {
		managedFile.load()
	}
	
	func save() {
		managedFile.saveIfNecessary()
	}
	
}

private extension AccountFile {

	func loadCallback() {
		var fileData: Data? = nil
		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(readingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { readURL in
			do {
				fileData = try Data(contentsOf: readURL)
			} catch {
				// Commented out because it’s not an error on first run.
				// TODO: make it so we know if it’s first run or not.
				//NSApplication.shared.presentError(error)
				os_log(.error, log: log, "Account read from disk failed: %@.", error.localizedDescription)
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "Account read from disk coordination failed: %@.", error.localizedDescription)
		}

		guard let accountData = fileData else {
			return
		}

		let decoder = JSONDecoder()
		let account: Account
		do {
			account = try decoder.decode(Account.self, from: accountData)
		} catch {
			os_log(.error, log: log, "Account read deserialization failed: %@.", error.localizedDescription)
			return
		}

		BatchUpdate.shared.perform {
			accountManager?.accountsDictionary[accountType.rawValue] = account
		}
	}
	
	func saveCallback() {
		
		guard let account = AccountManager.shared.accountsDictionary[accountType.rawValue] else { return }
		let encoder = JSONEncoder()
		let accountData: Data
		do {
			accountData = try encoder.encode(account)
		} catch {
			os_log(.error, log: log, "Account read deserialization failed: %@.", error.localizedDescription)
			return
		}

		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(writingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { writeURL in
			do {
				try accountData.write(to: writeURL)
			} catch let error as NSError {
				os_log(.error, log: log, "Account save to disk failed: %@.", error.localizedDescription)
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "Account save to disk coordination failed: %@.", error.localizedDescription)
		}
	}
	
}

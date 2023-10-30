//
//  AccountFile.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import os.log
import VinUtility

final class AccountFile {

	var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinOutlineKit")

	public static let filenameComponent = "account.plist"
	
	private weak var accountManager: AccountManager?
	private let fileURL: URL
	private let accountType: AccountType
	private lazy var managedFile = ManagedResourceFile(fileURL: fileURL,
													   load: { [weak self] in self?.loadCallback() },
													   save: { [weak self] in self?.saveCallback() })
	private var lastModificationDate: Date?

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
	
	func suspend() {
		managedFile.suspend()
	}
	
	func resume() {
		managedFile.resume()
	}
	
}

// MARK: Helpers

private extension AccountFile {

	func loadCallback() {
		var fileData: Data? = nil
		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(readingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { readURL in
			do {
				let resourceValues = try readURL.resourceValues(forKeys: [.contentModificationDateKey])
				if lastModificationDate != resourceValues.contentModificationDate {
					lastModificationDate = resourceValues.contentModificationDate
					fileData = try Data(contentsOf: readURL)
				}
			} catch {
				logger.error("Account read from disk failed: \(error.localizedDescription, privacy: .public)")
			}
		})
		
		if let error = errorPointer?.pointee {
			logger.error("Account read from disk coordination failed: \(error.localizedDescription, privacy: .public)")
		}

		guard let accountData = fileData else {
			return
		}

		let decoder = PropertyListDecoder()
		let account: Account
		do {
			account = try decoder.decode(Account.self, from: accountData)
		} catch {
			logger.error("Account read deserialization failed: \(error.localizedDescription, privacy: .public)")
			return
		}

		account.folder = fileURL.deletingLastPathComponent()
		
		accountManager?.accountsDictionary[accountType.rawValue] = account
	}
	
	func saveCallback() {
		
		guard let account = AccountManager.shared.accountsDictionary[accountType.rawValue] else { return }

		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary

		let accountData: Data
		do {
			accountData = try encoder.encode(account)
		} catch {
			logger.error("Account read serialization failed: \(error.localizedDescription, privacy: .public)")
			return
		}

		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(writingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { writeURL in
			do {
				try accountData.write(to: writeURL)
				let resourceValues = try writeURL.resourceValues(forKeys: [.contentModificationDateKey])
				lastModificationDate = resourceValues.contentModificationDate
			} catch let error as NSError {
				logger.error("Account save to disk failed: \(error.localizedDescription, privacy: .public)")
			}
		})
		
		if let error = errorPointer?.pointee {
			logger.error("Account save to disk coordination failed: \(error.localizedDescription, privacy: .public)")
		}
	}
	
}

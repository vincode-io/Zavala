//
//  AccountFile.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import OSLog
import VinUtility

final class AccountFile: ManagedResourceFile {

	public static let filenameComponent = "account.plist"
	private let accountType: AccountType
	private weak var accountManager: AccountManager?
	
	public init(fileURL: URL, accountType: AccountType, accountManager: AccountManager) {
		self.accountType = accountType
		self.accountManager = accountManager
		super.init(fileURL: fileURL)
	}
	
	public override func fileDidLoad(data: Data) {
		accountManager?.loadAccountFileData(data, accountType: accountType)
	}
	
	public override func fileWillSave() async -> Data? {
		return accountManager?.buildAccountFileData(accountType: accountType)
	}
	
}

//
//  File.swift
//  
//
//  Created by Maurice Parker on 2/7/24.
//

import Foundation

public extension AccountManager {
	
	func loadAccountFileData(_ data: Data, accountType: AccountType) {
		let decoder = PropertyListDecoder()
		let account: Account
		do {
			account = try decoder.decode(Account.self, from: data)
		} catch {
			logger.error("Account read deserialization failed: \(error.localizedDescription, privacy: .public)")
			return
		}
		
		let initialLoad = accountsDictionary[accountType.rawValue] == nil
		accountsDictionary[accountType.rawValue] = account
		
		if !initialLoad {
			account.accountDidReload()
		}
	}
	
	func buildAccountFileData(accountType: AccountType) -> Data? {
		guard let account = accountsDictionary[accountType.rawValue] else { return nil }
		
		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary
		
		let accountData: Data
		do {
			accountData = try encoder.encode(account)
		} catch {
			logger.error("Account read serialization failed: \(error.localizedDescription, privacy: .public)")
			return nil
		}
		
		return accountData
	}
	
}

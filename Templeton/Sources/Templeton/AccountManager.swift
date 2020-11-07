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
	
}

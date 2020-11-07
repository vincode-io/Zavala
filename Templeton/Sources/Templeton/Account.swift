//
//  Account.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Account: Identifiable, Codable {

	weak var manager: AccountManager?
	
	public var id: Int {
		type.rawValue
	}
	
	public var type: AccountType
	public var isActive: Bool
	public var folders: [Folder]?
	
	enum CodingKeys: String, CodingKey {
		case type = "type"
		case isActive = "isActive"
		case folders = "folders"
	}

	init(accountType: AccountType) {
		self.type = accountType
		self.isActive = true
		self.folders = [Folder]()
	}
	
}

//
//  Account.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Account: Identifiable, Codable {

	weak var manager: AccountManager?
	
	public var id: String {
		if type == .local {
			return "local"
		} else {
			return "cloudKit"
		}
	}
	
	public var type: AccountType
	public var folders: [Folder]?
	
	enum CodingKeys: String, CodingKey {
		case type = "type"
		case folders = "folders"
	}

}

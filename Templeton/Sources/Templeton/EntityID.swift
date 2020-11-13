//
//  EntityID.swift
//  
//
//  Created by Maurice Parker on 11/10/20.
//

import Foundation

public enum EntityID: Hashable, Equatable, Codable {
	case all
	case favorites
	case recents
	case account(Int)
	case folder(Int, String) // Account, Folder
	case outline(Int, String, String) // Account, Folder, Outline

	private enum CodingKeys: String, CodingKey {
		case type
		case accountID
		case folderID
		case outlineID
	}
	
	var isSmartProvider: Bool {
		switch self {
		case .all, .favorites, .recents:
			return true
		default:
			return false
		}
	}
	
	var isAccount: Bool {
		switch self {
		case .account(_):
			return true
		default:
			return false
		}
	}
	
	var isFolder: Bool {
		switch self {
		case .folder(_, _):
			return true
		default:
			return false
		}
	}
	
	var isOutline: Bool {
		switch self {
		case .outline(_, _, _):
			return true
		default:
			return false
		}
	}
	
	var accountID: Int {
		switch self {
		case .account(let accountID):
			return accountID
		case .folder(let accountID, _):
			return accountID
		case .outline(let accountID, _, _):
			return accountID
		default:
			fatalError()
		}
	}

	var folderID: String {
		switch self {
		case .folder(_, let folderID):
			return folderID
		case .outline(_, let folderID, _):
			return folderID
		default:
			fatalError()
		}
	}
	
	var outlineID: String {
		switch self {
		case .outline(_, _, let outlineID):
			return outlineID
		default:
			fatalError()
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		
		switch type {
		case "all":
			self = .all
		case "favorites":
			self = .favorites
		case "recents":
			self = .recents
		case "account":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			self = .account(accountID)
		case "folder":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			let folderID = try container.decode(String.self, forKey: .folderID)
			self = .folder(accountID, folderID)
		case "outline":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			let folderID = try container.decode(String.self, forKey: .folderID)
			let outlineID = try container.decode(String.self, forKey: .outlineID)
			self = .outline(accountID, folderID, outlineID)
		default:
			fatalError()
		}
	}
	
	public init?(userInfo: [AnyHashable: AnyHashable]) {
		guard let type = userInfo["type"] as? String else { return nil }
		
		switch type {
		case "all":
			self = .all
		case "favorites":
			self = .favorites
		case "recents":
			self = .recents
		case "account":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			self = .account(accountID)
		case "folder":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			guard let folderID = userInfo["folderID"] as? String else { return nil }
			self = .folder(accountID, folderID)
		case "outline":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			guard let folderID = userInfo["folderID"] as? String else { return nil }
			guard let outlineID = userInfo["outlineID"] as? String else { return nil }
			self = .outline(accountID, folderID, outlineID)
		default:
			return nil
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case .all:
			try container.encode("all", forKey: .type)
		case .favorites:
			try container.encode("favorites", forKey: .type)
		case .recents:
			try container.encode("recents", forKey: .type)
		case .account(let accountID):
			try container.encode("account", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
		case .folder(let accountID, let folderID):
			try container.encode("folder", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
			try container.encode(folderID, forKey: .folderID)
		case .outline(let accountID, let folderID, let outlineID):
			try container.encode("outline", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
			try container.encode(folderID, forKey: .folderID)
			try container.encode(outlineID, forKey: .outlineID)
		}
	}
	
	public var userInfo: [AnyHashable: AnyHashable] {
		switch self {
		case .all:
			return ["type": "all"]
		case .favorites:
			return ["type": "favorites"]
		case .recents:
			return ["type": "recents"]
		case .account(let accountID):
			return [
				"type": "account",
				"accountID": accountID
			]
		case .folder(let accountID, let folderID):
			return [
				"type": "folder",
				"accountID": accountID,
				"folderID": folderID
			]
		case .outline(let accountID, let folderID, let outlineID):
			return [
				"type": "outline",
				"accountID": accountID,
				"folderID": folderID,
				"outlineID": outlineID
			]
		}
	}
	

}

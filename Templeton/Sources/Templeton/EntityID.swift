//
//  EntityID.swift
//  
//
//  Created by Maurice Parker on 11/10/20.
//

import Foundation

public enum EntityID: CustomStringConvertible, Hashable, Equatable, Codable {
	case account(Int)
	case document(Int, String) // Account, Document
	case accountDocuments(Int) // Account
	case search(String) // Search String

	public var accountID: Int {
		switch self {
		case .account(let accountID):
			return accountID
		case .document(let accountID, _):
			return accountID
		case .accountDocuments(let accountID):
			return accountID
		default:
			fatalError()
		}
	}

	public var description: String {
		switch self {
		case .account(let id):
			return "account:\(id)"
		case .document(let accountID, let documentID):
			return "document:\(accountID)_\(documentID)"
		case .search(let searchText):
			return "search:\(searchText)"
		case .accountDocuments(let id):
			return "accountDocuments:\(id)"
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
	
	var isDocument: Bool {
		switch self {
		case .document(_, _):
			return true
		default:
			return false
		}
	}
	
	var documentUUID: String {
		switch self {
		case .document(_, let documentID):
			return documentID
		default:
			fatalError()
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case type
		case searchText
		case accountID
		case documentID
	}
	
	public init?(description: String) {
		if description.starts(with: "account:") {
			let idString = description.suffix(from: description.index(description.startIndex, offsetBy: 8))
			if let accountID = Int(idString) {
				self = .account(accountID)
				return
			}
		} else if description.starts(with: "document:") {
			let idString = description.suffix(from: description.index(description.startIndex, offsetBy: 9))
			let ids = idString.split(separator: "_")
			if let accountID = Int(ids[0]) {
				self = .document(accountID, String(ids[1]))
				return
			}
		} else if description.starts(with: "search:") {
			let searchText = description.suffix(from: description.index(description.startIndex, offsetBy: 7))
			self = .search(String(searchText))
			return
		} else if description.starts(with: "accountDocuments:") {
			let idString = description.suffix(from: description.index(description.startIndex, offsetBy: 18))
			if let accountID = Int(idString) {
				self = .accountDocuments(accountID)
				return
			}
		}
		return nil
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		
		switch type {
		case "account":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			self = .account(accountID)
		case "document":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			let documentID = try container.decode(String.self, forKey: .documentID)
			self = .document(accountID, documentID)
		case "search":
			let searchText = try container.decode(String.self, forKey: .searchText)
			self = .search(searchText)
		case "accountDocuments":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			self = .accountDocuments(accountID)
		default:
			fatalError()
		}
	}
	
	public init?(userInfo: [AnyHashable: AnyHashable]) {
		guard let type = userInfo["type"] as? String else { return nil }
		
		switch type {
		case "account":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			self = .account(accountID)
		case "document":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			guard let documentID = userInfo["documentID"] as? String else { return nil }
			self = .document(accountID, documentID)
		case "search":
			guard let searchText = userInfo["searchText"] as? String else { return nil }
			self = .search(searchText)
		case "accountDocuments":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			self = .accountDocuments(accountID)
		default:
			return nil
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case .account(let accountID):
			try container.encode("account", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
		case .document(let accountID, let documentID):
			try container.encode("outline", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
			try container.encode(documentID, forKey: .documentID)
		case .search(let searchText):
			try container.encode("search", forKey: .type)
			try container.encode(searchText, forKey: .searchText)
		case .accountDocuments(let accountID):
			try container.encode("accountDocuments", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
		}
	}
	
	public var userInfo: [AnyHashable: AnyHashable] {
		switch self {
		case .account(let accountID):
			return [
				"type": "account",
				"accountID": accountID
			]
		case .document(let accountID, let documentID):
			return [
				"type": "outline",
				"accountID": accountID,
				"documentID": documentID
			]
		case .search(let searchText):
			return [
				"type": "search",
				"searchText": searchText
			]
		case .accountDocuments(let accountID):
			return [
				"type": "accountDocuments",
				"accountID": accountID
			]
		}
	}
	

}

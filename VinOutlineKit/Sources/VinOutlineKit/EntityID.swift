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
	case row(Int, String, String) // Account, Document, Row
	case image(Int, String, String, String) // Account, Document, Row, Image
	case allDocuments(Int) // Account
	case recentDocuments(Int) // Account
	case tagDocuments(Int, String) // Account, Tag
	case search(String) // Search String

	public var accountID: Int {
		switch self {
		case .account(let accountID):
			return accountID
		case .document(let accountID, _):
			return accountID
		case .row(let accountID, _, _):
			return accountID
		case .image(let accountID, _, _, _):
			return accountID
		case .allDocuments(let accountID):
			return accountID
		case .recentDocuments(let accountID):
			return accountID
		case .tagDocuments(let accountID, _):
			return accountID
		default:
			fatalError()
		}
	}

	public var documentUUID: String {
		switch self {
		case .document(_, let documentID):
			return documentID
		case .row(_, let documentID, _):
			return documentID
		case .image(_, let documentID, _, _):
			return documentID
		default:
			fatalError()
		}
	}
	
	public var rowUUID: String {
		switch self {
		case .row(_, _, let rowID):
			return rowID
		case .image(_, _, let rowID, _):
			return rowID
		default:
			fatalError()
		}
	}
	
	public var imageUUID: String {
		switch self {
		case .image(_, _, _, let imageID):
			return imageID
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
		case .row(let accountID, let documentID, let rowID):
			return "row:\(accountID)_\(documentID)_\(rowID)"
		case .image(let accountID, let documentID, let rowID, let imageID):
			return "image:\(accountID)_\(documentID)_\(rowID)_\(imageID)"
		case .search(let searchText):
			return "search:\(searchText)"
		case .allDocuments(let id):
			return "allDocuments:\(id)"
		case .recentDocuments(let id):
			return "recentDocuments:\(id)"
		case .tagDocuments(let accountID, let tagID):
			return "tagDocuments:\(accountID)_\(tagID)"
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
				"type": "document",
				"accountID": accountID,
				"documentID": documentID
			]
		case .row(let accountID, let documentID, let rowID):
			return [
				"type": "row",
				"accountID": accountID,
				"documentID": documentID,
				"rowID": rowID
			]
		case .image(let accountID, let documentID, let rowID, let imageID):
			return [
				"type": "image",
				"accountID": accountID,
				"documentID": documentID,
				"rowID": rowID,
				"imageID": imageID
			]
		case .search(let searchText):
			return [
				"type": "search",
				"searchText": searchText
			]
		case .allDocuments(let accountID):
			return [
				"type": "allDocuments",
				"accountID": accountID
			]
		case .recentDocuments(let accountID):
			return [
				"type": "recentDocuments",
				"accountID": accountID
			]
		case .tagDocuments(let accountID, let tagID):
			return [
				"type": "tagDocuments",
				"accountID": accountID,
				"tagID": tagID
			]
		}
	}

	public var url: URL? {
		switch self {
		case .document(let acct, let documentUUID):
			var urlComponents = URLComponents()
			urlComponents.scheme = "zavala"
			urlComponents.host = "document"
			
			var queryItems = [URLQueryItem]()
			queryItems.append(URLQueryItem(name: "accountID", value: String(acct)))
			queryItems.append(URLQueryItem(name: "documentUUID", value: String(documentUUID)))
			urlComponents.queryItems = queryItems
			
			return urlComponents.url!
		case .row(let acct, let documentUUID, let rowUUID):
			var urlComponents = URLComponents()
			urlComponents.scheme = "zavala"
			urlComponents.host = "row"
			
			var queryItems = [URLQueryItem]()
			queryItems.append(URLQueryItem(name: "accountID", value: String(acct)))
			queryItems.append(URLQueryItem(name: "documentUUID", value: String(documentUUID)))
			queryItems.append(URLQueryItem(name: "rowUUID", value: String(rowUUID)))
			urlComponents.queryItems = queryItems
			
			return urlComponents.url!
		default:
			return nil
		}
	}
	
	public var isAccount: Bool {
		switch self {
		case .account(_):
			return true
		default:
			return false
		}
	}
	
	public var isSystemCollection: Bool {
		switch self {
		case .allDocuments(_):
			return true
		case .recentDocuments(_):
			return true
		default:
			return false
		}
	}
	
	public var isDocument: Bool {
		switch self {
		case .document(_, _):
			return true
		default:
			return false
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case type
		case searchText
		case accountID
		case documentID
		case rowID
		case imageID
		case tagID
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
		} else if description.starts(with: "row:") {
			let idString = description.suffix(from: description.index(description.startIndex, offsetBy: 4))
			let ids = idString.split(separator: "_")
			if let accountID = Int(ids[0]) {
				self = .row(accountID, String(ids[1]), String(ids[2]))
				return
			}
		} else if description.starts(with: "image:") {
			let idString = description.suffix(from: description.index(description.startIndex, offsetBy: 6))
			let ids = idString.split(separator: "_")
			if let accountID = Int(ids[0]) {
				self = .image(accountID, String(ids[1]), String(ids[2]), String(ids[3]))
				return
			}
		} else if description.starts(with: "search:") {
			let searchText = description.suffix(from: description.index(description.startIndex, offsetBy: 7))
			self = .search(String(searchText))
			return
		} else if description.starts(with: "allDocuments:") {
			let idString = description.suffix(from: description.index(description.startIndex, offsetBy: 13))
			if let accountID = Int(idString) {
				self = .allDocuments(accountID)
				return
			}
		} else if description.starts(with: "recentDocuments:") {
			let idString = description.suffix(from: description.index(description.startIndex, offsetBy: 16))
			if let accountID = Int(idString) {
				self = .recentDocuments(accountID)
				return
			}
		} else if description.starts(with: "tagDocuments:") {
			let idString = description.suffix(from: description.index(description.startIndex, offsetBy: 13))
			let ids = idString.split(separator: "_")
			if let accountID = Int(ids[0]) {
				self = .tagDocuments(accountID, String(ids[1]))
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
		case "row":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			let documentID = try container.decode(String.self, forKey: .documentID)
			let rowID = try container.decode(String.self, forKey: .rowID)
			self = .row(accountID, documentID, rowID)
		case "image":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			let documentID = try container.decode(String.self, forKey: .documentID)
			let rowID = try container.decode(String.self, forKey: .rowID)
			let imageID = try container.decode(String.self, forKey: .imageID)
			self = .image(accountID, documentID, rowID, imageID)
		case "search":
			let searchText = try container.decode(String.self, forKey: .searchText)
			self = .search(searchText)
		case "allDocuments":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			self = .allDocuments(accountID)
		case "recentDocuments":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			self = .recentDocuments(accountID)
		case "tagDocuments":
			let accountID = try container.decode(Int.self, forKey: .accountID)
			let tagID = try container.decode(String.self, forKey: .tagID)
			self = .tagDocuments(accountID, tagID)
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
		case "row":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			guard let documentID = userInfo["documentID"] as? String else { return nil }
			guard let rowID = userInfo["rowID"] as? String else { return nil }
			self = .row(accountID, documentID, rowID)
		case "image":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			guard let documentID = userInfo["documentID"] as? String else { return nil }
			guard let rowID = userInfo["rowID"] as? String else { return nil }
			guard let imageID = userInfo["imageID"] as? String else { return nil }
			self = .image(accountID, documentID, rowID, imageID)
		case "search":
			guard let searchText = userInfo["searchText"] as? String else { return nil }
			self = .search(searchText)
		case "allDocuments":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			self = .allDocuments(accountID)
		case "recentDocuments":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			self = .recentDocuments(accountID)
		case "tagDocuments":
			guard let accountID = userInfo["accountID"] as? Int else { return nil }
			guard let tagID = userInfo["tagID"] as? String else { return nil }
			self = .tagDocuments(accountID, tagID)
		default:
			return nil
		}
	}
	
	public init?(url: URL) {
		guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
			  let accountIDString = urlComponents.queryItems?.first(where: { $0.name == "accountID" })?.value,
			  let accountID = Int(accountIDString),
			  let documentUUID = urlComponents.queryItems?.first(where: { $0.name == "documentUUID" })?.value else {
			return nil
		}
		self = .document(accountID, documentUUID)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case .account(let accountID):
			try container.encode("account", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
		case .document(let accountID, let documentID):
			try container.encode("document", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
			try container.encode(documentID, forKey: .documentID)
		case .row(let accountID, let documentID, let rowID):
			try container.encode("row", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
			try container.encode(documentID, forKey: .documentID)
			try container.encode(rowID, forKey: .rowID)
		case .image(let accountID, let documentID, let rowID, let imageID):
			try container.encode("image", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
			try container.encode(documentID, forKey: .documentID)
			try container.encode(rowID, forKey: .rowID)
			try container.encode(imageID, forKey: .imageID)
		case .search(let searchText):
			try container.encode("search", forKey: .type)
			try container.encode(searchText, forKey: .searchText)
		case .allDocuments(let accountID):
			try container.encode("allDocuments", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
		case .recentDocuments(let accountID):
			try container.encode("recentDocuments", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
		case .tagDocuments(let accountID, let tagID):
			try container.encode("tagDocuments", forKey: .type)
			try container.encode(accountID, forKey: .accountID)
			try container.encode(tagID, forKey: .tagID)
		}
	}

}

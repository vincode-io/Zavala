//
//  Folder.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation
import RSCore

public final class Folder: Identifiable, Equatable, Codable, OutlineProvider {
	
	public var accountID: Int?
	public var id: String?
	public var name: String?
	public var image: RSImage? {
		return RSImage(systemName: "folder")
	}
	public var outlines: [Outline]?

	public var outlineProviderID: OutlineProviderID {
		guard let accountID = accountID, let id = id else { fatalError() }
		return .folder(accountID, id)
	}

	enum CodingKeys: String, CodingKey {
		case accountID = "accountID"
		case id = "id"
		case name = "name"
		case outlines = "outlines"
	}
	
	init(accountID: Int, name: String) {
		self.accountID = accountID
		self.id = UUID().uuidString
		self.name = name
		self.outlines = [Outline]()
	}
	
	public static func == (lhs: Folder, rhs: Folder) -> Bool {
		return lhs.id == rhs.id
	}
}

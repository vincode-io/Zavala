//
//  Headline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Headline: Identifiable, Equatable, Codable {
	
	public var id: String
	public var text: Data?
	public var headlines: [Headline]?

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case text = "text"
		case headlines = "headlines"
	}

	public init() {
		self.id = UUID().uuidString
		headlines = [Headline]()
	}
	
	public init(plainText: String) {
		self.id = UUID().uuidString
		text = plainText.data(using: .utf8)
		headlines = [Headline]()
	}
	
	public static func == (lhs: Headline, rhs: Headline) -> Bool {
		return lhs.id == rhs.id
	}
}

//
//  Headline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Headline: Identifiable, Equatable, Codable {
	
	public var id: String?
	public var text: Data?
	public var headlines: [Headline]?

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case text = "text"
		case headlines = "headlines"
	}
	
	public static func == (lhs: Headline, rhs: Headline) -> Bool {
		return lhs.id == rhs.id
	}
}

//
//  Headline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Headline: Identifiable, Codable {
	
	public var id: String?
	public var text: Data?
	public var headlines: [Headline]?

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case text = "text"
		case headlines = "headlines"
	}
	
}

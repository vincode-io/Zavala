//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Outline: Identifiable, Codable {
	
	public var id: String?
	public var created: Date?
	public var updated: Date?
	public var headlines: [Headline]?
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case created = "created"
		case updated = "updated"
		case headlines = "headlines"
	}
	
}

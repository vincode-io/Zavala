//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Outline: Identifiable, Equatable, Codable {
	
	public var id: String?
	public var name: String?
	public var created: Date?
	public var updated: Date?
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
		case created = "created"
		case updated = "updated"
	}
	
	public static func == (lhs: Outline, rhs: Outline) -> Bool {
		return lhs.id == rhs.id
	}
	
}

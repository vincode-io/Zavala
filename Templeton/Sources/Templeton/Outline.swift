//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Outline: Identifiable, Codable {
	
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
	
}

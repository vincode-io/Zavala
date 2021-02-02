//
//  Tag.swift
//  
//
//  Created by Maurice Parker on 1/28/21.
//

import Foundation

public class Tag: Identifiable, Codable, Equatable {
	
	public var id: String
	public var name: String
	
	private enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
	}
	
	public init(name: String) {
		self.id = UUID().uuidString
		self.name = name
	}
	
	public static func == (lhs: Tag, rhs: Tag) -> Bool {
		return lhs.id == rhs.id
	}
	
}

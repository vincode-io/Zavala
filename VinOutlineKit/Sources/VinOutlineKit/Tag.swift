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
	
	public var level: Int {
		name.split(separator: "/").count - 1
	}

	public var partialName: String {
		if let lastElement = name.split(separator: "/").last {
			return String(lastElement)
		}
		return name
	}

	public var parentName: String? {
		guard let index = name.lastIndex(of: "/") else { return nil }
		return String(name[..<index])
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
	}
	
	public init(name: String) {
		self.id = UUID().uuidString
		self.name = name
	}
	
	public func isChild(of tag: Tag) -> Bool {
		if let range = name.range(of: "\(tag.name)/") {
			if !name[range.upperBound...].contains("/") {
				return true
			}
		}
		return false
	}
	
	public static func == (lhs: Tag, rhs: Tag) -> Bool {
		return lhs.id == rhs.id
	}
	
}

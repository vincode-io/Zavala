//
//  Folder.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Folder: Identifiable, Equatable, Codable {

	public var id: String?
	public var name: String?
	public var outlines: [Outline]?
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
		case outlines = "outlines"
	}
	
	init(name: String) {
		self.id = UUID().uuidString
		self.name = name
		self.outlines = [Outline]()
	}
	
	public static func == (lhs: Folder, rhs: Folder) -> Bool {
		return lhs.id == rhs.id
	}
}

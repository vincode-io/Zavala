//
//  Folder.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Folder: Identifiable, Codable {

	public var id: String?
	public var name: String?
	public var outlines: [Outline]?
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
		case outlines = "outlines"
	}
	
}

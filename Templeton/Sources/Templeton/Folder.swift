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
	public var outlineIDs: [Outline.ID]?
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
		case outlineIDs = "outlineIDs"
	}
	
}

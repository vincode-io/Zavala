//
//  Image.swift
//  
//
//  Created by Maurice Parker on 4/7/21.
//

import Foundation

public struct Image: Identifiable, Codable, Equatable {
	
	public var id: EntityID
	public var isInNotes: Bool
	public var offset: Int
	public var data: Data

	private enum CodingKeys: String, CodingKey {
		case id = "id"
		case isInNotes = "isInNotes"
		case offset = "offset"
		case data = "data"
	}
	
	public init(id: EntityID, isInNotes: Bool, offset: Int, data: Data) {
		self.id = id
		self.isInNotes = isInNotes
		self.offset = offset
		self.data = data
	}
	
	public static func == (lhs: Image, rhs: Image) -> Bool {
		return lhs.id == rhs.id && lhs.isInNotes == rhs.isInNotes && lhs.offset == rhs.offset && lhs.data == rhs.data
	}
	
	public func duplicate(accountID: Int, documentUUID: String, rowUUID: String) -> Image {
		let id = EntityID.image(accountID, documentUUID, rowUUID, UUID().uuidString)
		return Image(id: id, isInNotes: isInNotes, offset: offset, data: data)
	}
	
}

//
//  Image.swift
//  
//
//  Created by Maurice Parker on 4/7/21.
//

import Foundation
import OSLog

public class Image: Identifiable, Codable, Equatable {
	
	public var isCloudKit: Bool {
		return outline?.isCloudKit ?? false
	}

	public var cloudKitMetaData: Data?
	public var id: EntityID

	var ancestorIsInNotes: Bool?
	var serverIsInNotes: Bool?
	public var isInNotes: Bool? {
		willSet {
			if isCloudKit && ancestorIsInNotes == nil {
				ancestorIsInNotes = isInNotes
			}
		}
	}

	var ancestorOffset: Int?
	var serverOffset: Int?
	public var offset: Int? {
		willSet {
			if isCloudKit && ancestorOffset == nil {
				ancestorOffset = offset
			}
		}
	}

	var ancestorData: Data?
	var serverData: Data?
	public var data: Data? {
		willSet {
			if isCloudKit && ancestorData == nil {
				ancestorData = data
			}
		}
	}
    
    public weak var outline: Outline?

	var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "VinOutlineKit")

	var tempCloudKitDataURL: URL?
	
	private enum CodingKeys: String, CodingKey {
		case cloudKitMetaData
		case id
		case ancestorIsInNotes
		case isInNotes
		case ancestorOffset
		case offset
		case ancestorData
		case data
	}
	
	public init(outline: Outline, id: EntityID, isInNotes: Bool?, offset: Int?, data: Data?) {
        self.outline = outline
		self.id = id
		self.isInNotes = isInNotes
		self.offset = offset
		self.data = data
	}
	
	public convenience init(outline: Outline, id: EntityID) {
		self.init(outline: outline, id: id, isInNotes: nil, offset: nil, data: nil)
	}

	public static func == (lhs: Image, rhs: Image) -> Bool {
		return lhs.id == rhs.id && lhs.isInNotes == rhs.isInNotes && lhs.offset == rhs.offset && lhs.data == rhs.data
	}
	
    public func duplicate(outline: Outline, accountID: Int, documentUUID: String, rowUUID: String) -> Image {
		let id = EntityID.image(accountID, documentUUID, rowUUID, UUID().uuidString)
        return Image(outline: outline, id: id, isInNotes: isInNotes, offset: offset, data: data)
	}
	
}

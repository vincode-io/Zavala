//
//  Image.swift
//  
//
//  Created by Maurice Parker on 4/7/21.
//

import Foundation
import OSLog

@MainActor
final public class Image: Identifiable {
	
	public var isCloudKit: Bool {
		return outline?.isCloudKit ?? false
	}

	public var cloudKitMetaData: Data? {
		didSet {
			outline?.imagesFile?.markAsDirty()
		}
	}
	
	public var isCloudKitMerging: Bool = false
	
	nonisolated public let id: EntityID

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
	
	init(coder: ImageCoder) {
		self.cloudKitMetaData = coder.cloudKitMetaData
		self.id = coder.id
		self.ancestorIsInNotes = coder.ancestorIsInNotes
		self.isInNotes = coder.isInNotes
		self.ancestorOffset = coder.ancestorOffset
		self.offset = coder.offset
		self.ancestorData = coder.ancestorData
		self.data = coder.data
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

    public func duplicate(outline: Outline, accountID: Int, documentUUID: String, rowUUID: String) -> Image {
		let id = EntityID.image(accountID, documentUUID, rowUUID, UUID().uuidString)
        return Image(outline: outline, id: id, isInNotes: isInNotes, offset: offset, data: data)
	}

	func toCoder() -> ImageCoder {
		return ImageCoder(cloudKitMetaData: cloudKitMetaData, 
						  id: id,
						  ancestorIsInNotes: ancestorIsInNotes,
						  isInNotes: isInNotes,
						  ancestorOffset: ancestorOffset,
						  offset: offset,
						  ancestorData: ancestorData,
						  data: data)
	}
	
//	public static func == (lhs: Image, rhs: Image) -> Bool {
//		return lhs.id == rhs.id && lhs.isInNotes == rhs.isInNotes && lhs.offset == rhs.offset && lhs.data == rhs.data
//	}
	
}

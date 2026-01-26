//
//  Created by Maurice Parker on 6/27/24.
//

import Foundation
import OrderedCollections

enum RowCoderError: LocalizedError {
	case unableToDeserialize
	var errorDescription: String? {
		return .rowDeserializationError
	}
}

struct RowCoder: Codable {

	public let cloudKitMetaData: Data?
	public let id: String
	public let ancestorTopicData: Data?
	public let topicData: Data?
	public let ancestorNoteData: Data?
	public let noteData: Data?
	public let isExpanded: Bool
	public let ancestorIsComplete: Bool?
	public let isComplete: Bool?
	public let ancestorRowOrder: OrderedSet<String>?
	public let rowOrder: OrderedSet<String>

	// Fractional indexing properties
	public let order: String
	public let parentID: String?
	public let ancestorOrder: String?
	public let ancestorParentID: String?

	private enum CodingKeys: String, CodingKey {
		case cloudKitMetaData
		case id
		case ancestorTopicData
		case topicData
		case ancestorNoteData
		case noteData
		case isExpanded
		case ancestorIsComplete
		case isComplete
		case ancestorRowOrder
		case rowOrder
		case order
		case parentID
		case ancestorOrder
		case ancestorParentID
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.ancestorIsComplete = try? container.decode(Bool.self, forKey: .ancestorIsComplete)
		if let isComplete = try? container.decode(Bool.self, forKey: .isComplete) {
			self.isComplete = isComplete
		} else {
			self.isComplete = false
		}

		cloudKitMetaData = try? container.decode(Data.self, forKey: .cloudKitMetaData)

		if let id = try? container.decode(String.self, forKey: .id) {
			self.id = id
		} else if let id = try? container.decode(EntityID.self, forKey: .id) {
			self.id = id.rowUUID
		} else {
			throw RowCoderError.unableToDeserialize
		}

		if let isExpanded = try? container.decode(Bool.self, forKey: .isExpanded) {
			self.isExpanded = isExpanded
		} else {
			self.isExpanded = true
		}

		if let rowOrderCloudKitValue = try? container.decode([String].self, forKey: .ancestorRowOrder) {
			self.ancestorRowOrder = OrderedSet(rowOrderCloudKitValue)
		} else {
			self.ancestorRowOrder = nil
		}

		if let rowOrder = try? container.decode([String].self, forKey: .rowOrder) {
			self.rowOrder = OrderedSet(rowOrder)
		} else if let rowOrder = try? container.decode([EntityID].self, forKey: .rowOrder) {
			self.rowOrder = OrderedSet(rowOrder.map { $0.rowUUID })
		} else {
			throw RowCoderError.unableToDeserialize
		}

		ancestorTopicData = try? container.decode(Data.self, forKey: .ancestorTopicData)
		topicData = try? container.decode(Data.self, forKey: .topicData)
		ancestorNoteData = try? container.decode(Data.self, forKey: .ancestorNoteData)
		noteData = try? container.decode(Data.self, forKey: .noteData)

		// Fractional indexing properties (with defaults for backward compatibility during migration)
		self.order = (try? container.decode(String.self, forKey: .order)) ?? ""
		self.parentID = try? container.decode(String.self, forKey: .parentID)
		self.ancestorOrder = try? container.decode(String.self, forKey: .ancestorOrder)
		self.ancestorParentID = try? container.decode(String.self, forKey: .ancestorParentID)
	}

	init(cloudKitMetaData: Data?,
		 id: String,
		 ancestorTopicData: Data?,
		 topicData: Data?,
		 ancestorNoteData: Data?,
		 noteData: Data?,
		 isExpanded: Bool,
		 ancestorIsComplete: Bool?,
		 isComplete: Bool?,
		 ancestorRowOrder: OrderedSet<String>?,
		 rowOrder: OrderedSet<String>,
		 order: String,
		 parentID: String?,
		 ancestorOrder: String?,
		 ancestorParentID: String?) {
		self.cloudKitMetaData = cloudKitMetaData
		self.id = id
		self.ancestorTopicData = ancestorTopicData
		self.topicData = topicData
		self.ancestorNoteData = ancestorNoteData
		self.noteData = noteData
		self.isExpanded = isExpanded
		self.ancestorIsComplete = ancestorIsComplete
		self.isComplete = isComplete
		self.ancestorRowOrder = ancestorRowOrder
		self.rowOrder = rowOrder
		self.order = order
		self.parentID = parentID
		self.ancestorOrder = ancestorOrder
		self.ancestorParentID = ancestorParentID
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(cloudKitMetaData, forKey: .cloudKitMetaData)
		try container.encode(id, forKey: .id)
		try container.encode(ancestorTopicData, forKey: .ancestorTopicData)
		try container.encode(topicData, forKey: .topicData)
		try container.encode(ancestorNoteData, forKey: .ancestorNoteData)
		try container.encode(noteData, forKey: .noteData)
		try container.encode(isExpanded, forKey: .isExpanded)
		try container.encode(ancestorIsComplete, forKey: .ancestorIsComplete)
		try container.encode(isComplete, forKey: .isComplete)
		try container.encode(ancestorRowOrder, forKey: .ancestorRowOrder)
		try container.encode(rowOrder, forKey: .rowOrder)
		try container.encode(order, forKey: .order)
		try container.encode(parentID, forKey: .parentID)
		try container.encode(ancestorOrder, forKey: .ancestorOrder)
		try container.encode(ancestorParentID, forKey: .ancestorParentID)
	}

}

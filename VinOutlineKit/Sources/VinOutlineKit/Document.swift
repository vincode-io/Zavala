//
//  Document.swift
//  
//
//  Created by Maurice Parker on 12/24/20.
//

import Foundation
import CloudKit

public extension Notification.Name {
	static let DocumentDidChangeBySync = Notification.Name(rawValue: "DocumentDidChangeBySync")
	static let DocumentTitleDidChange = Notification.Name(rawValue: "DocumentTitleDidChange")
	static let DocumentUpdatedDidChange = Notification.Name(rawValue: "DocumentUpdatedDidChange")
	static let DocumentMetaDataDidChange = Notification.Name(rawValue: "DocumentMetaDataDidChange")
	static let DocumentDidDelete = Notification.Name(rawValue: "DocumentDidDelete")
	static let DocumentSharingDidChange = Notification.Name(rawValue: "DocumentSharingDidChange")
}

public enum Document: Equatable, Hashable, Codable {
	case outline(Outline)
	case dummy
	
	private enum CodingKeys: String, CodingKey {
		case type
		case outline
	}
	
	public var id: EntityID {
		switch self {
		case .outline(let outline):
			return outline.id
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
	public var account: Account? {
		if case .outline(let outline) = self {
			return outline.account
		}
		return nil
	}
	
	public var outline: Outline? {
		if case .outline(let outline) = self {
			return outline
		}
		return nil
	}
	
	public var title: String? {
		switch self {
		case .outline(let outline):
			return outline.title
		case .dummy:
			return nil
		}
	}
	
	public var disambiguator: Int? {
		switch self {
		case .outline(let outline):
			return outline.disambiguator
		case .dummy:
			return nil
		}
	}
	
	public var textContent: String {
		switch self {
		case .outline(let outline):
			return outline.textContent()
		case .dummy:
			return ""
		}
	}
	
	public var formattedPlainText: String {
		switch self {
		case .outline(let outline):
			return outline.markdownList()
		case .dummy:
			return ""
		}
	}
	
	public var tagCount: Int {
		switch self {
		case .outline(let outline):
			return outline.tagCount
		case .dummy:
			return 0
		}
	}
	
	public var tags: [Tag]? {
		switch self {
		case .outline(let outline):
			return outline.tags
		case .dummy:
			return nil
		}
	}
	
	public var created: Date? {
		switch self {
		case .outline(let outline):
			return outline.created
		case .dummy:
			return nil
		}
	}
	
	public var updated: Date? {
		switch self {
		case .outline(let outline):
			return outline.updated
		case .dummy:
			return nil
		}
	}
	
	public var isEmpty: Bool {
		switch self {
		case .outline(let outline):
			return outline.isEmpty
		case .dummy:
			return true
		}
	}
	
	public var isCollaborating: Bool {
		switch self {
		case .outline(let outline):
			return outline.iCollaborating
		case .dummy:
			return false
		}
	}
	
	public var isCloudKit: Bool {
		switch self {
		case .outline(let outline):
			return outline.isCloudKit
		case .dummy:
			return false
		}
	}
	
	public var shareRecord: CKShare? {
		get {
			switch self {
			case .outline(let outline):
				return outline.cloudKitShareRecord
			case .dummy:
				fatalError("The dummy document shouldn't be accessed in this way.")
			}
		}
		set {
			switch self {
			case .outline(let outline):
				outline.cloudKitShareRecord = newValue
			case .dummy:
				fatalError("The dummy document shouldn't be accessed in this way.")
			}
		}
	}
	
	var shareRecordID: CKRecord.ID? {
		get {
			switch self {
			case .outline(let outline):
				return outline.shareRecordID
			case .dummy:
				fatalError("The dummy document shouldn't be accessed in this way.")
			}
		}
		set {
			switch self {
			case .outline(let outline):
				outline.shareRecordID = newValue
			case .dummy:
				fatalError("The dummy document shouldn't be accessed in this way.")
			}
		}
	}
	
	var zoneID: CKRecordZone.ID? {
		get {
			switch self {
			case .outline(let outline):
				return outline.zoneID
			case .dummy:
				fatalError("The dummy document shouldn't be accessed in this way.")
			}
		}
		set {
			switch self {
			case .outline(let outline):
				outline.zoneID = newValue
			case .dummy:
				fatalError("The dummy document shouldn't be accessed in this way.")
			}
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		
		switch type {
		case "outline":
			let outline = try container.decode(Outline.self, forKey: .outline)
			self = .outline(outline)
		default:
			fatalError()
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case .outline(let outline):
			try container.encode("outline", forKey: .type)
			try container.encode(outline, forKey: .outline)
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
	public func update(disambiguator: Int) {
		switch self {
		case .outline(let outline):
			outline.update(disambiguator: disambiguator)
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
	public func reassignAccount(_ accountID: Int) {
		switch self {
		case .outline(let outline):
			outline.reassignAccount(accountID)
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}

	public func createTag(_ tag: Tag) {
		switch self {
		case .outline(let outline):
			outline.createTag(tag)
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
	public func deleteTag(_ tag: Tag) {
		switch self {
		case .outline(let outline):
			outline.deleteTag(tag)
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
    public func hasAnyTag(_ tags: [Tag]) -> Bool {
        switch self {
        case .outline(let outline):
            return outline.hasAnyTag(tags)
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
        }
    }
    
	public func hasTag(_ tag: Tag) -> Bool {
		switch self {
		case .outline(let outline):
			return outline.hasTag(tag)
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
	public func deleteAllBacklinks() {
		switch self {
		case .outline(let outline):
			outline.deleteAllBacklinks()
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}

	public func load() {
		switch self {
		case .outline(let outline):
			outline.load()
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}

	public func unload() {
		switch self {
		case .outline(let outline):
			outline.unload()
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}

	public func save() {
		switch self {
		case .outline(let outline):
			outline.save()
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}

	public func forceSave() {
		switch self {
		case .outline(let outline):
			outline.forceSave()
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}

	public func suspend() {
		switch self {
		case .outline(let outline):
			outline.suspend()
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}

	public func resume() {
		switch self {
		case .outline(let outline):
			outline.resume()
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}

	public func delete() {
		switch self {
		case .outline(let outline):
			outline.delete()
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
	public func documentDidDelete() {
		switch self {
		case .outline(let outline):
			outline.outlineDidDelete()
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
	public func duplicate() -> Document {
		switch self {
		case .outline(let outline):
			return Document.outline(outline.duplicate())
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
	public func filename(representation: DataRepresentation) -> String {
		switch self {
		case .outline(let outline):
			return outline.filename(representation: representation)
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
	public func requestCloudKitUpdateForSelf() {
		switch self {
		case .outline(let outline):
			outline.requestCloudKitUpdateForSelf()
		case .dummy:
			fatalError("The dummy document shouldn't be accessed in this way.")
		}
	}
	
	public static func == (lhs: Document, rhs: Document) -> Bool {
		return lhs.id == rhs.id
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
}

public extension Array where Element == Document {
	
	var title: String {
		ListFormatter.localizedString(byJoining: self.compactMap({ $0.title }).sorted())
	}
	
}

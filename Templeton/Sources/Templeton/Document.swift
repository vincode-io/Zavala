//
//  Document.swift
//  
//
//  Created by Maurice Parker on 12/24/20.
//

import Foundation
import CloudKit

public extension Notification.Name {
	static let DocumentTitleDidChange = Notification.Name(rawValue: "DocumentTitleDidChange")
	static let DocumentUpdatedDidChange = Notification.Name(rawValue: "DocumentUpdatedDidChange")
	static let DocumentMetaDataDidChange = Notification.Name(rawValue: "DocumentMetaDataDidChange")
	static let DocumentDidDelete = Notification.Name(rawValue: "DocumentDidDelete")
	static let DocumentSharingDidChange = Notification.Name(rawValue: "DocumentSharingDidChange")
}

public enum Document: Equatable, Codable {
	case outline(Outline)
	
	private enum CodingKeys: String, CodingKey {
		case type
		case outline
	}
	
	public var id: EntityID {
		switch self {
		case .outline(let outline):
			return outline.id
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
		}
	}
	
	public var string: String? {
		switch self {
		case .outline(let outline):
			return outline.string()
		}
	}
	
	public var tags: [Tag]? {
		switch self {
		case .outline(let outline):
			return outline.tags
		}
	}
	
	public var updated: Date? {
		switch self {
		case .outline(let outline):
			return outline.updated
		}
	}
	
	public var isEmpty: Bool {
		switch self {
		case .outline(let outline):
			return outline.isEmpty
		}
	}
	
	public var isShared: Bool {
		switch self {
		case .outline(let outline):
			return outline.isShared
		}
	}
	
	var shareRecordID: CKRecord.ID? {
		get {
			switch self {
			case .outline(let outline):
				return outline.shareRecordID
			}
		}
		set {
			switch self {
			case .outline(let outline):
				outline.shareRecordID = newValue
			}
		}
	}
	
	var zoneID: CKRecordZone.ID? {
		get {
			switch self {
			case .outline(let outline):
				return outline.zoneID
			}
		}
		set {
			switch self {
			case .outline(let outline):
				outline.zoneID = newValue
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
		}
	}
	
	public func reassignAccount(_ accountID: Int) {
		switch self {
		case .outline(let outline):
			outline.reassignAccount(accountID)
		}
	}

	public func createTag(_ tag: Tag) {
		switch self {
		case .outline(let outline):
			outline.createTag(tag)
		}
	}
	
	public func deleteTag(_ tag: Tag) {
		switch self {
		case .outline(let outline):
			outline.deleteTag(tag)
		}
	}
	
	public func hasTag(_ tag: Tag) -> Bool {
		switch self {
		case .outline(let outline):
			return outline.hasTag(tag)
		}
	}
	
	public func load() {
		switch self {
		case .outline(let outline):
			outline.load()
		}
	}

	public func unload() {
		switch self {
		case .outline(let outline):
			outline.unload()
		}
	}

	public func save() {
		switch self {
		case .outline(let outline):
			outline.save()
		}
	}

	public func forceSave() {
		switch self {
		case .outline(let outline):
			outline.forceSave()
		}
	}

	public func suspend() {
		switch self {
		case .outline(let outline):
			outline.suspend()
		}
	}

	public func resume() {
		switch self {
		case .outline(let outline):
			outline.resume()
		}
	}

	public func delete() {
		switch self {
		case .outline(let outline):
			outline.delete()
		}
	}
	
	public func documentDidDelete() {
		switch self {
		case .outline(let outline):
			outline.outlineDidDelete()
		}
	}
	
	public func duplicate() -> Document {
		switch self {
		case .outline(let outline):
			return Document.outline(outline.duplicate())
		}
	}
	
}

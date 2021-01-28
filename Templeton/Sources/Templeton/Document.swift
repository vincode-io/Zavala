//
//  Document.swift
//  
//
//  Created by Maurice Parker on 12/24/20.
//

import Foundation

public extension Notification.Name {
	static let DocumentTitleDidChange = Notification.Name(rawValue: "DocumentTitleDidChange")
	static let DocumentMetaDataDidChange = Notification.Name(rawValue: "DocumentMetaDataDidChange")
	static let DocumentDidDelete = Notification.Name(rawValue: "DocumentDidDelete")
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
	
	public var content: String? {
		switch self {
		case .outline(let outline):
			return outline.markdown()
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
	
	public func reassignID(_ entityID: EntityID) {
		switch self {
		case .outline(let outline):
			return outline.id = entityID
		}
	}

	public func load() {
		switch self {
		case .outline(let outline):
			return outline.load()
		}
	}

	public func save() {
		switch self {
		case .outline(let outline):
			return outline.save()
		}
	}

	public func forceSave() {
		switch self {
		case .outline(let outline):
			return outline.forceSave()
		}
	}

	public func delete() {
		switch self {
		case .outline(let outline):
			return outline.delete()
		}
	}
	
}

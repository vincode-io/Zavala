//
//  EntityID+.swift
//  Zavala
//
//  Created by Maurice Parker on 7/1/24.
//

import Foundation
import AppIntents
import VinOutlineKit

extension EntityID: @retroactive Identifiable {}
extension EntityID: @retroactive DisplayRepresentable {}
extension EntityID: @retroactive TypeDisplayRepresentable {}
extension EntityID: @retroactive InstanceDisplayRepresentable {}
extension EntityID: @retroactive CustomLocalizedStringResourceConvertible {}
extension EntityID: @retroactive AppValue {}
extension EntityID: @retroactive _IntentValue {}
extension EntityID: @retroactive PersistentlyIdentifiable {}
extension EntityID: @retroactive AppEntity, @retroactive EntityIdentifierConvertible {
	public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Entity ID")
	public static let defaultQuery = EntityIDEntityQuery()
	
	public var id: EntityID {
		return self
	}
	
	public var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: description)
	}
	
	public var entityIdentifierString: String {
		return description
	}
	
	public static func entityIdentifier(for entityIdentifierString: String) -> VinOutlineKit.EntityID? {
		return VinOutlineKit.EntityID(description: entityIdentifierString)
	}

	public struct EntityIDEntityQuery: EntityQuery {
		public init() {}
		public func entities(for identifiers: [EntityID.ID]) async throws -> [EntityID] {
			return identifiers
		}

	}
}

//
//  EntityID+.swift
//  Zavala
//
//  Created by Maurice Parker on 7/1/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct EntityIDAppEntity: TransientAppEntity, EntityIdentifierConvertible, Hashable {
	
	public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Entity ID")
	
	public var entityID: EntityID?
	
	public init() {
		
	}
	
	public init(entityID: EntityID) {
		self.entityID = entityID
	}
	
	public var displayRepresentation: DisplayRepresentation {
		guard let entityID else { fatalError("Must populate the entityID first.") }
		return DisplayRepresentation(stringLiteral: entityID.description)
	}
	
	public var entityIdentifierString: String {
		guard let entityID else { fatalError("Must populate the entityID first.")}
		return entityID.description
	}
	
	static func entityIdentifier(for entityIdentifierString: String) -> EntityIDAppEntity? {
		guard let entityID = EntityID(description: entityIdentifierString) else {
			return nil
		}
		return EntityIDAppEntity(entityID: entityID)
	}
	
}

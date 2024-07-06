//
//  Row.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct RowAppEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Row")
	static let defaultQuery = RowAppEntityQuery()

	@Property(title: "ID")
	var id: EntityIDAppEntity

	@Property(title: "Entity ID")
	var entityID: EntityIDAppEntity?

    @Property(title: "Topic")
    var topic: String?

    @Property(title: "Note")
    var note: String?

    @Property(title: "Complete")
    var complete: Bool?

    @Property(title: "Expanded")
    var expanded: Bool?

    @Property(title: "Level")
    var level: Int?

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: topic ?? "")
	}

    struct RowAppEntityQuery: EntityQuery {
        func entities(for identifiers: [RowAppEntity.ID]) async throws -> [RowAppEntity] {
            // TODO: return Row entities with the specified identifiers here.
            return []
        }

    }
	

}


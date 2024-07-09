//
//  Row.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct RowAppEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Row")
	static let defaultQuery = RowAppEntityQuery()

	@Property(title: "ID")
	var id: EntityID

	@Property(title: "Entity ID")
	var entityID: EntityID

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

	init() {
	}

	@MainActor
	init(row: Row) {
		self.id = row.entityID
		self.entityID = self.id
		self.topic = row.topicMarkdown(type: .markdown)
		self.note = row.noteMarkdown(type: .markdown)
		self.complete = row.isComplete
		self.expanded = row.isExpanded
		self.level = row.trueLevel
	}

    struct RowAppEntityQuery: EntityQuery {
        func entities(for identifiers: [RowAppEntity.ID]) async throws -> [RowAppEntity] {
            // TODO: return Row entities with the specified identifiers here.
            return []
        }

    }
	

}


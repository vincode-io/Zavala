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

    struct RowAppEntityQuery: EntityQuery, ZavalaAppIntent {
		
        func entities(for entityIDs: [RowAppEntity.ID]) async throws -> [RowAppEntity] {
			await resume()
			
			var results = [RowAppEntity]()
			
			for entityID in entityIDs {
				if let outline = await AccountManager.shared.findDocument(entityID)?.outline {
					await outline.load()
					
					if let row = await outline.findRow(id: entityID.rowUUID) {
						await results.append(RowAppEntity(row: row))
					}
					
					await outline.unload()
				}
			}
			
			await suspend()
			return results
        }

    }

}


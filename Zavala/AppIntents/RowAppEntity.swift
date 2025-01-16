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
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("label.text.row", comment: "Row"))
	static let defaultQuery = RowAppEntityQuery()

	@Property(title: LocalizedStringResource("label.text.id", comment: "ID"))
	var id: EntityID

	@Property(title: LocalizedStringResource("label.text.entity-id", comment: "Entity ID"))
	var entityID: EntityID

    @Property(title: LocalizedStringResource("label.text.topic", comment: "topic"))
    var topic: String?

    @Property(title: LocalizedStringResource("label.text.note", comment: "Note"))
    var note: String?

    @Property(title: LocalizedStringResource("label.text.complete", comment: "Complete"))
    var complete: Bool?

    @Property(title: LocalizedStringResource("label.text.expanded", comment: "Expanded"))
    var expanded: Bool?

    @Property(title: LocalizedStringResource("label.text.level", comment: "Level"))
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
				if let outline = await appDelegate.accountManager.findDocument(entityID)?.outline {
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


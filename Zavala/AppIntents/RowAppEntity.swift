//
//  Row.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import CoreTransferable
import AppIntents
import VinOutlineKit

struct RowAppEntity: AppEntity, Transferable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("label.text.row", comment: "Row"))
	static let defaultQuery = FindRowsEntityQuery()

	@Property(title: LocalizedStringResource("label.text.id", comment: "ID"))
	var id: EntityID

	@Property(title: LocalizedStringResource("label.text.entity-id", comment: "Entity ID"))
	var entityID: EntityID

	@Property(title: LocalizedStringResource("label.text.outline", comment: "Outline"))
	var outline: OutlineAppEntity?

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

	@Property(title: LocalizedStringResource("label.text.row-order", comment: "Row Order"))
	var rowOrder: Int?

	@Property(title: LocalizedStringResource("label.text.url", comment: "URL"))
	var url: URL?

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: topic ?? "")
	}

	static var transferRepresentation: some TransferRepresentation {
		ProxyRepresentation { entity in
			entity.id.description
		}
	}

	init() {
	}

	@MainActor
	init(row: Row) {
		self.id = row.entityID
		self.entityID = self.id
		let documentEntityID = EntityID.document(row.entityID.accountID, row.entityID.documentUUID)
		if let outline = appDelegate.accountManager.findDocument(documentEntityID)?.outline {
			self.outline = OutlineAppEntity(outline: outline)
		}
		self.topic = row.topicMarkdown(type: .markdown)
		self.note = row.noteMarkdown(type: .markdown)
		self.complete = row.isComplete
		self.expanded = row.isExpanded
		self.level = row.trueLevel
		self.url = row.entityID.url
	}

}


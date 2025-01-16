//
//  Outline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/1/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct OutlineAppEntity: AppEntity {
	static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("label.text.outline", comment: "Outline"))
	static let defaultQuery = OutlineEntityQuery()
	
	@Property(title: LocalizedStringResource("label.text.id", comment: "ID"))
    var id: EntityID

	@Property(title: LocalizedStringResource("label.text.entity-id", comment: "Entity ID"))
	var entityID: EntityID

    @Property(title: LocalizedStringResource("label.text.title", comment: "Title"))
    var title: String?

	@Property(title: LocalizedStringResource("label.text.tags", comment: "Tags"))
	var tags: [String]?

    @Property(title: LocalizedStringResource("label.text.owner-name", comment: "Owner Name"))
    var ownerName: String?

    @Property(title: LocalizedStringResource("label.text.owner-email", comment: "Owner Email"))
    var ownerEmail: String?

    @Property(title: LocalizedStringResource("label.text.owner-url", comment: "Owner URL"))
    var ownerURL: String?

	@Property(title: LocalizedStringResource("label.text.created", comment: "Created"))
	var created: Date?

	@Property(title: LocalizedStringResource("label.text.updated", comment: "Updated"))
	var updated: Date?

    @Property(title: LocalizedStringResource("label.text.url", comment: "URL"))
    var url: URL?

    var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: title ?? .noTitleLabel)
    }

    init() {
    }

	@MainActor
	init(outline: Outline) {
		self.id = outline.id
		self.entityID = self.id
		self.title = outline.title
		self.tags = outline.tags.map({ $0.name })
		self.ownerName = outline.ownerName
		self.ownerEmail = outline.ownerEmail
		self.ownerURL = outline.ownerURL
		self.created = outline.created
		self.updated = outline.updated
		self.url = outline.id.url
	}
	
}

struct OutlineEntityQuery: EntityQuery, ZavalaAppIntent {
	
	func entities(for entityIDs: [OutlineAppEntity.ID]) async -> [OutlineAppEntity] {
		await resume()
		
		var results = [OutlineAppEntity]()
		for entityID in entityIDs {
			if let outline = await appDelegate.accountManager.findDocument(entityID)?.outline {
				await results.append(OutlineAppEntity(outline: outline))
			}
		}
		
		await suspend()
		return results
	}
	
}

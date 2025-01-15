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
	static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Outline")
	static let defaultQuery = OutlineEntityQuery()
	
    @Property(title: "ID")
    var id: EntityID

	@Property(title: "Entity ID")
	var entityID: EntityID

    @Property(title: "Title")
    var title: String?

	@Property(title: "Tags")
	var tags: [String]?

    @Property(title: "Owner Name")
    var ownerName: String?

    @Property(title: "Owner Email")
    var ownerEmail: String?

    @Property(title: "Owner URL")
    var ownerURL: String?

	@Property(title: "Created")
	var created: Date?

	@Property(title: "Updated")
	var updated: Date?

    @Property(title: "URL")
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

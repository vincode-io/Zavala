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
	
	typealias DefaultQuery = OutlineEntityQuery
	
	static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Outline")

	static var defaultQuery: OutlineEntityQuery {
		return OutlineEntityQuery()
	}
	
    @Property(title: "ID")
    var id: EntityIDAppEntity

	@Property(title: "Entity ID")
	var entityID: EntityIDAppEntity

    @Property(title: "Title")
    var title: String?

    @Property(title: "Owner Name")
    var ownerName: String?

    @Property(title: "Owner Email")
    var ownerEmail: String?

    @Property(title: "Owner URL")
    var ownerURL: String?

    @Property(title: "URL")
    var url: URL?

    var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: title ?? .noTitleLabel)
    }

    init() {
    }

	@MainActor
	init(outline: Outline) {
		self.id = EntityIDAppEntity(entityID: outline.id)
		self.entityID = self.id
		self.title = outline.title
		self.ownerName = outline.ownerName
		self.ownerEmail = outline.ownerEmail
		self.ownerURL = outline.ownerURL
		self.url = outline.id.url
	}
	
	struct OutlineEntityQuery: EntityStringQuery, ZavalaAppIntent {
	
		func entities(for identifiers: [OutlineAppEntity.ID]) async -> [OutlineAppEntity] {
			await resume()
			
			var results = [OutlineAppEntity]()
			for identifier in identifiers {
				if let entityID = identifier.entityID, let outline = await AccountManager.shared.findDocument(entityID)?.outline {
					await results.append(OutlineAppEntity(outline: outline))
				}
			}
			
			await suspend()
			return results
		}
		
		func entities(matching string: String) async -> [OutlineAppEntity] {
			await resume()
			
			var results = [OutlineAppEntity]()
			for document in await AccountManager.shared.documents {
				if await document.title?.localizedCaseInsensitiveContains(string) ?? false, let outline = await document.outline {
					await results.append(OutlineAppEntity(outline: outline))
				}
			}

			await suspend()
			return results
		}
	}
	
}

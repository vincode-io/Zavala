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
	
    @Property(title: "ID")
    var id: EntityIDAppEntity

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
        DisplayRepresentation(title: "Unimplemented")
    }

    init() {
    }

	@MainActor
	init(outline: Outline) {
		self.id = EntityIDAppEntity(entityID: outline.id)
		self.title = outline.title
		self.ownerName = outline.ownerName
		self.ownerEmail = outline.ownerEmail
		self.ownerURL = outline.ownerURL
		self.url = outline.id.url
	}
	
	static var defaultQuery: OutlineEntityQuery {
		return OutlineEntityQuery()
	}
	
	struct OutlineEntityQuery: EntityStringQuery {
		
		func entities(for identifiers: [OutlineAppEntity.ID]) -> [OutlineAppEntity] {
			[]
		}
		
		func entities(matching string: String) -> [OutlineAppEntity] {
			[]
		}
	}
	
}

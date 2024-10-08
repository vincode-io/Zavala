//
//  Outline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct Outline: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Outline")

    @Property(title: "Entity ID")
    var entityID: EntityID?

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

    struct OutlineQuery: EntityQuery {
        func entities(for identifiers: [Outline.ID]) async throws -> [Outline] {
            // TODO: return Outline entities with the specified identifiers here.
            return []
        }

        func suggestedEntities() async throws -> [Outline] {
            // TODO: return likely Outline entities here.
            // This method is optional; the default implementation returns an empty array.
            return []
        }
    }
    static var defaultQuery = OutlineQuery()

    var id: String // if your identifier is not a String, conform the entity to EntityIdentifierConvertible.
    var displayString: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)")
    }

    init(id: String, displayString: String) {
        self.id = id
        self.displayString = displayString
    }
}


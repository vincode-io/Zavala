//
//  Outline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/1/24.
//

import Foundation
import CoreTransferable
import AppIntents
import VinOutlineKit

struct OutlineAppEntity: AppEntity, Equatable {
	static let typeDisplayRepresentation = TypeDisplayRepresentation(
		name: LocalizedStringResource("label.text.outline-name", defaultValue: "Outline", table: "AppIntents", comment: "The name of the Outline type. Singular/plural forms live in AppIntents.stringsdict; Shortcuts uses the plural for 'Find Outlines'."),
		numericFormat: LocalizedStringResource("label.text.outline-count", defaultValue: "\(placeholder: .int) Outlines", comment: "A count of Outlines, e.g. '2 Outlines'")
	)
	static let defaultQuery = FindOutlinesEntityQuery()
	
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

	@Property(title: LocalizedStringResource("label.text.account-type", comment: "Account Type"))
	var accountType: AccountTypeAppEnum?

    var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(stringLiteral: title ?? .noTitleLabel)
    }

    init() {
    }

	static func == (lhs: OutlineAppEntity, rhs: OutlineAppEntity) -> Bool {
		lhs.id == rhs.id
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
		
		if outline.account?.type == .cloudKit {
			self.accountType = .iCloud
		} else {
			self.accountType = .onMyDevice
		}
	}
	
}



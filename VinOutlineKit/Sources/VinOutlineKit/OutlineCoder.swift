//
//  Created by Maurice Parker on 6/25/24.
//

import Foundation

struct OutlineCoder: Codable {
	
	public let cloudKitMetaData: Data?
	public let id: EntityID
	public let ancestorTitle: String?
	public let title: String?
	public let ancestorDisambiguator: Int?
	public let disambiguator: Int?
	public let ancestorCreated: Date?
	public let created: Date?
	public let ancestorUpdated: Date?
	public let updated: Date?
	public let ancestorAutomaticallyCreateLinks: Bool?
	public let automaticallyCreateLinks: Bool?
	public let ancestorAutomaticallyChangeLinkTitles: Bool?
	public let automaticallyChangeLinkTitles: Bool?
	public let ancestorCheckSpellingWhileTyping: Bool?
	public let checkSpellingWhileTyping: Bool?
	public let ancestorCorrectSpellingAutomatically: Bool?
	public let correctSpellingAutomatically: Bool?
	public let ancestorOwnerName: String?
	public let ownerName: String?
	public let ancestorOwnerEmail: String?
	public let ownerEmail: String?
	public let ancestorOwnerURL: String?
	public let ownerURL: String?
	public let verticleScrollState: Int?
	public let isFilterOn: Bool?
	public let isCompletedFiltered: Bool?
	public let isNotesFiltered: Bool?
	public let focusRowID: String?
	public let selectionRowID: EntityID?
	public let selectionIsInNotes: Bool?
	public let selectionLocation: Int?
	public let selectionLength: Int?
	public let ancestorTagIDs: [String]?
	public let tagIDs: [String]?
	public let ancestorDocumentLinks: [EntityID]?
	public let documentLinks: [EntityID]?
	public let ancestorDocumentBacklinks: [EntityID]?
	public let documentBacklinks: [EntityID]?
	public let ancestorHasAltLinks: Bool?
	public let hasAltLinks: Bool?
	public let cloudKitZoneName: String?
	public let cloudKitZoneOwner: String?
	public let cloudKitShareRecordName: String?
	public let cloudKitShareRecordData: Data?

	enum CodingKeys: String, CodingKey {
		case cloudKitMetaData
		case id
		case ancestorTitle
		case title
		case ancestorDisambiguator
		case disambiguator
		case ancestorCreated
		case created
		case ancestorUpdated
		case updated
		case ancestorAutomaticallyCreateLinks
		case automaticallyCreateLinks
		case ancestorAutomaticallyChangeLinkTitles = "ancestorAutoLinkingEnabled"
		case automaticallyChangeLinkTitles = "autoLinkingEnabled"
		case ancestorCheckSpellingWhileTyping
		case checkSpellingWhileTyping
		case ancestorCorrectSpellingAutomatically
		case correctSpellingAutomatically
		case ancestorOwnerName
		case ownerName
		case ancestorOwnerEmail
		case ownerEmail
		case ancestorOwnerURL
		case ownerURL
		case verticleScrollState
		case isFilterOn
		case isCompletedFiltered
		case isNotesFiltered
		case focusRowID
		case selectionRowID
		case selectionIsInNotes
		case selectionLocation
		case selectionLength
		case ancestorTagIDs
		case tagIDs = "tagIDS"
		case ancestorDocumentLinks
		case documentLinks
		case ancestorDocumentBacklinks
		case documentBacklinks
		case ancestorHasAltLinks
		case hasAltLinks
		case cloudKitZoneName
		case cloudKitZoneOwner
		case cloudKitShareRecordName
		case cloudKitShareRecordData
	}
	
}

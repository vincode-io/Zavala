//
//  NoteAppEntity.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import CoreSpotlight
import CoreTransferable
import UniformTypeIdentifiers
import VinOutlineKit

/// Maps a Zavala Outline to the Notes domain note schema.
@available(iOS 27.0, *)
@AppEntity(schema: .notes.note)
struct NoteAppEntity: IndexedEntity, Transferable {
	static let isAssistantOnly = true
	static let defaultQuery = NoteAppEntityQuery()

	let id: EntityID

	var name: AttributedString

	/// Generating the content requires loading the Outline from disk, so it is only done when the system asks for it.
	@DeferredProperty(indexingKey: \.textContent)
	var content: AttributedString? {
		get async throws {
			try await Self.content(for: id)
		}
	}

	/// Zavala doesn't support attachments or pinning Outlines.
	var attachments: [IntentFile]
	var isPinned: Bool

	var creationDate: Date?
	var modificationDate: Date?
	var folder: FolderAppEntity?

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: "\(name)")
	}

	// MARK: IndexedEntity

	/// Notes reach the index by being associated with their Outline's Spotlight item (see NoteIndexer), so that
	/// there's one Spotlight result per Outline. They aren't hidden from Spotlight because hideInSpotlight keeps an
	/// entity out of the index entirely, which also hides it from Siri.
	var attributeSet: CSSearchableItemAttributeSet {
		let attributeSet = defaultAttributeSet
		attributeSet.title = String(name.characters)
		attributeSet.contentCreationDate = creationDate
		attributeSet.contentModificationDate = modificationDate
		return attributeSet
	}

	// MARK: Transferable

	/// Lets Siri and Apple Intelligence pass an Outline to other apps, e.g. "Send the current outline to Bob".
	/// Rich text comes first so that apps that display it get the printed list with its nesting and formatting.
	/// Apps that only take plain text, such as messaging apps, get an indented plain text version. A Markdown
	/// file comes last for apps that accept attachments.
	static var transferRepresentation: some TransferRepresentation {
		DataRepresentation(exportedContentType: .rtf) { note in
			try await MainActor.run {
				let printList = try unlockedOutline(for: note.id).printList()
				let range = NSRange(location: 0, length: printList.length)
				return try printList.data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
			}
		}

		DataRepresentation(exportedContentType: .utf8PlainText) { note in
			try await MainActor.run {
				let outline = try unlockedOutline(for: note.id)
				return Data(outline.markdownList(format: false).utf8)
			}
		}

		// The system's Markdown type rather than VinUtility's .md, because the App Intents metadata
		// processor only accepts types defined by UniformTypeIdentifiers
		DataRepresentation(exportedContentType: .markdown) { note in
			try await MainActor.run {
				let outline = try unlockedOutline(for: note.id)
				return Data(outline.markdownList(format: true).utf8)
			}
		}
		.suggestedFileName { note in
			// Slashes aren't allowed in file names
			"\(String(note.name.characters).replacing("/", with: "-")).md"
		}
	}

	@MainActor
	init(outline: Outline) {
		self.id = outline.id
		self.name = AttributedString(outline.title ?? .noTitleLabel)
		self.attachments = []
		self.isPinned = false
		self.creationDate = outline.created
		self.modificationDate = outline.updated

		if let account = outline.account, let folderTag = outline.folderTag {
			self.folder = FolderAppEntity(tag: folderTag, account: account)
		}
	}

	/// Finds the Outline for a note. Locked Outlines are refused so that their content never leaves the app.
	@MainActor
	static func unlockedOutline(for id: EntityID) throws -> Outline {
		guard let outline = appDelegate.accountManager.findDocument(id)?.outline else {
			throw ZavalaAppIntentError.outlineNotFound
		}

		guard !(outline.isLocked ?? false) else {
			throw ZavalaAppIntentError.outlineIsLocked
		}

		return outline
	}

	@MainActor
	private static func content(for id: EntityID) throws -> AttributedString {
		let body = try unlockedOutline(for: id).markdownList(format: false)
		return AttributedString(body)
	}
}

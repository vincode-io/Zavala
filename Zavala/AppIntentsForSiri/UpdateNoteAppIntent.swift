//
//  UpdateNoteAppIntent.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import VinOutlineKit

/// Renames an Outline and/or moves it to a different folder. Moving replaces the Tag currently used as the
/// Outline's folder with the new folder's Tag and leaves the Outline's other Tags alone.
@available(iOS 27.0, *)
@AppIntent(schema: .notes.updateNote)
struct UpdateNoteAppIntent: ZavalaAppIntent {
	static let isAssistantOnly = true

	var target: NoteAppEntity
	var name: AttributedString?
	var attachments: [IntentFile]?
	var isPinned: Bool?
	var folder: FolderAppEntity?

	@MainActor
	func perform() async throws -> some ReturnsValue<NoteAppEntity> {
		resume()

		guard let outline = findOutline(target) else {
			await suspend()
			throw ZavalaAppIntentError.outlineNotFound
		}

		guard !(outline.isLocked ?? false) else {
			await suspend()
			throw ZavalaAppIntentError.outlineIsLocked
		}

		// Validate the folder before making any changes, so that a failure doesn't leave a partial update
		var newFolderTag: Tag?
		if let folder {
			guard let (folderAccount, tag) = findAccountAndTag(folder) else {
				await suspend()
				throw AppIntentsForSiriError.folderNotFound
			}
			guard folderAccount == outline.account else {
				await suspend()
				throw AppIntentsForSiriError.folderInDifferentAccount
			}
			newFolderTag = tag
		}

		if let name {
			outline.update(title: String(name.characters))
		}

		if let newFolderTag, newFolderTag != outline.folderTag {
			if let currentFolderTag = outline.folderTag {
				outline.deleteTag(currentFolderTag)
				outline.account?.deleteTag(currentFolderTag)
			}
			outline.createTag(newFolderTag)
		}

		DocumentIndexer.updateIndex(for: .outline(outline))

		await suspend()
		return .result(value: NoteAppEntity(outline: outline))
	}
}

//
//  CreateNoteAppIntent.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import VinOutlineKit

/// Creates a new Outline. If a folder is given, the Outline is created in that folder's Account and tagged with it.
@available(iOS 27.0, *)
@AppIntent(schema: .notes.createNote)
struct CreateNoteAppIntent: ZavalaAppIntent {
	static let isAssistantOnly = true

	var name: AttributedString
	var content: AttributedString?
	var attachments: [IntentFile]
	var isPinned: Bool
	var folder: FolderAppEntity?

	@MainActor
	func perform() async throws -> some ReturnsValue<NoteAppEntity> {
		resume()

		let account: Account
		var tags = [Tag]()

		if let folder {
			guard let (folderAccount, tag) = findAccountAndTag(folder) else {
				await suspend()
				throw AppIntentsForSiriError.folderNotFound
			}
			account = folderAccount
			tags.append(tag)
		} else {
			guard let defaultAccount = appDelegate.accountManager.sortedActiveAccounts.first else {
				await suspend()
				throw ZavalaAppIntentError.unavailableAccount
			}
			account = defaultAccount
		}

		guard let outline = account.createOutline(title: String(name.characters), tags: tags).outline else {
			await suspend()
			throw ZavalaAppIntentError.unexpectedError
		}

		outline.update(defaults: AppDefaults.shared.outlineDefaults)

		if let content {
			await outline.appendNoteContent(content)
		}

		DocumentIndexer.updateIndex(for: .outline(outline))

		await suspend()
		return .result(value: NoteAppEntity(outline: outline))
	}
}

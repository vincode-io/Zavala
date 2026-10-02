//
//  AppendTextToNoteAppIntent.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import VinOutlineKit

/// Appends the given text to the end of an Outline as new rows.
@available(iOS 27.0, *)
@AppIntent(schema: .notes.appendText)
struct AppendTextToNoteAppIntent: ZavalaAppIntent {
	static let isAssistantOnly = true

	var content: AttributedString
	var target: NoteAppEntity

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

		await outline.appendNoteContent(content)

		DocumentIndexer.updateIndex(for: .outline(outline))

		await suspend()
		return .result(value: NoteAppEntity(outline: outline))
	}
}

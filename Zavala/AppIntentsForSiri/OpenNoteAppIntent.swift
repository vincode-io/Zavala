//
//  OpenNoteAppIntent.swift
//  Zavala
//
//  Created by Maurice Parker on 10/1/26.
//

import Foundation
import AppIntents
import VinOutlineKit

/// Opens an Outline in Zavala, e.g. "Open the Zavala Tasks outline".
@available(iOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenNoteAppIntent: OpenIntent, ZavalaAppIntent {
	static let isAssistantOnly = true

	var target: NoteAppEntity

	@MainActor
	func perform() async throws -> some IntentResult {
		guard let outline = findOutline(target) else {
			throw ZavalaAppIntentError.outlineNotFound
		}

		await showDocument(outline.id)
		return .result()
	}
}

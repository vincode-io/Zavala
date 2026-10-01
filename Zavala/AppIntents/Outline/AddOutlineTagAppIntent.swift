//
//  AddOutlineTag.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct AddOutlineTagAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "AddOutlineTagIntent"
	static let title: LocalizedStringResource = LocalizedStringResource("intent.title.add-outline-tag", comment: "Intent title: Add Outline Tag")
	static let description = IntentDescription(LocalizedStringResource("intent.description.add-outline-tag", comment: "Intent description: Add a Tag to the given Outline."))

	@Parameter(title: LocalizedStringResource("intent.parameter.outline", comment: "Intent parameter: Outline"))
	var outline: OutlineAppEntity

	@Parameter(title: LocalizedStringResource("intent.parameter.tag-name", comment: "Intent paramter: Tag Name"))
    var tagName: String

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary-add-tag-\(\.$tagName)-to-outline-\(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline, \.$tagName)) { outline, tagName in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.add-tag-\(tagName)-to-\(outline)", comment: "Intent prediction: Add <tagname> to <outline>"),
                subtitle: nil
            )
        }
    }

	@MainActor
    func perform() async throws -> some IntentResult {
		resume()
		
		guard let outline = findOutline(outline) else {
			await suspend()
			throw ZavalaAppIntentError.outlineNotFound
		}

		guard !(outline.isLocked ?? false) else {
			await suspend()
			throw ZavalaAppIntentError.outlineIsLocked
		}

		guard let tag = outline.account?.createTag(name: tagName) else {
			await suspend()
			throw ZavalaAppIntentError.unexpectedError
		}
		
		outline.createTag(tag)
		DocumentIndexer.updateIndex(for: .outline(outline))
		await suspend()
		
		return .result()
    }
}

private extension IntentDialog {
    static func tagNameParameterPrompt(tagName: String) -> Self {
		return IntentDialog(LocalizedStringResource("intent.prompt.tag-name-to-add-\(tagName)", comment: "What is the <tagname> to add?"))
    }
}


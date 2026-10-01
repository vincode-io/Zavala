//
//  RemoveOutlineTag.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct RemoveOutlineTagAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "RemoveOutlineTagIntent"
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.remove-outline-tag", comment: "Intent title: Remove Outline Tag")
    static let description = IntentDescription(LocalizedStringResource("intent.description.remove-outline-tag", comment: "Intent title: Removes a Tag from the given Outline."))
	
    @Parameter(title: LocalizedStringResource("intent.parameter.outline", comment: "Intent parameter: Outline"))
	var outline: OutlineAppEntity

    @Parameter(title: LocalizedStringResource("intent.parameter.tag-name", comment: "Intent parameter: Tag Name"))
    var tagName: String

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.remove-\(\.$tagName)-from-\(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline, \.$tagName)) { outline, tagName in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.remove-\(tagName)-from-\(outline)", comment: "Intent prediction: Remove <tag name> from <outline>"),
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

		if let tag = outline.account?.findTag(name: tagName) {
			outline.deleteTag(tag)
			outline.account?.deleteTag(tag)
			DocumentIndexer.updateIndex(for: .outline(outline))
		}

		await suspend()
		return .result()
    }
	
}

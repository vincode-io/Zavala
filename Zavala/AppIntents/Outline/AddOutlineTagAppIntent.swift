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
    static let title: LocalizedStringResource = "Add Outline Tag"
    static let description = IntentDescription("Add a Tag to the given Outline.")

    @Parameter(title: "Outline")
	var outline: OutlineAppEntity

    @Parameter(title: "Tag Name")
    var tagName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$tagName) to \(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline, \.$tagName)) { outline, tagName in
            DisplayRepresentation(
                title: "Add \(tagName) to \(outline)",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
		await resume()
		
		guard let outline = await findOutline(outline) else {
			await suspend()
			throw ZavalaAppIntentError.outlineNotFound
		}
		
		guard let tag = await outline.account?.createTag(name: tagName) else {
			await suspend()
			throw ZavalaAppIntentError.unexpectedError
		}
		
		await outline.createTag(tag)
		await suspend()
		
		return .result()
    }
}

private extension IntentDialog {
    static func tagNameParameterPrompt(tagName: String) -> Self {
        "What is the \(tagName) to add?"
    }
}


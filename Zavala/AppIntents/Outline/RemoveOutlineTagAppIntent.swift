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
    static let title: LocalizedStringResource = "Remove Outline Tag"
    static let description = IntentDescription("Removes a Tag from the given Outline.")

    @Parameter(title: "Outline")
	var outline: OutlineAppEntity

    @Parameter(title: "Tag Name")
    var tagName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Remove \(\.$tagName) from \(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline, \.$tagName)) { outline, tagName in
            DisplayRepresentation(
                title: "Remove \(tagName) from \(outline)",
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
		
		if let tag = await outline.account?.findTag(name: tagName) {
			await outline.deleteTag(tag)
			await outline.account?.deleteTag(tag)
		}

		await suspend()
		return .result()
    }
	
}

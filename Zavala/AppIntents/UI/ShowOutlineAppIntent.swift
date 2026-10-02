//
//  ShowOutline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import UIKit
import AppIntents
import VinOutlineKit

struct ShowOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "ShowOutlineIntent"
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.show-outline", comment: "Show Outline")
    static let description = IntentDescription(LocalizedStringResource("intent.description.show-outline", comment: "Shows the given outline in the foremost window of Zavala."))
	static let openAppWhenRun = true
	
    @Parameter(title: LocalizedStringResource("intent.parameter.outline", comment: "Intent parameter: Outline"))
	var outline: OutlineAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary-show-\(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline)) { outline in
            DisplayRepresentation(
                title: LocalizedStringResource("intent.prediction.show-\(outline)", comment: "Show <outline>"),
                subtitle: nil
            )
        }
    }

	@MainActor
	func perform() async throws -> some IntentResult {
		await showDocument(outline.id)
        return .result()
    }
}



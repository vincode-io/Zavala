//
//  ShowOutline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct ShowOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "ShowOutlineIntent"
    static let title: LocalizedStringResource = "Show Outline"
    static let description = IntentDescription("Shows the given outline in the foremost window of Zavala.")

    @Parameter(title: "Outline")
	var outline: OutlineAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline)) { outline in
            DisplayRepresentation(
                title: "Show \(outline!)",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        // TODO: Place your refactored intent handler code here.
        return .result()
    }
}



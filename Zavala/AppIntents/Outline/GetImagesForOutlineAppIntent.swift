//
//  GetImagesForOutline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct GetImagesForOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetImagesForOutlineIntent"
    static let title: LocalizedStringResource = "Get Images For Outline"
    static let description = IntentDescription("Gets all the images associated with the given Outline. Useful for integrating with outlines exported as Markdown.")

    @Parameter(title: "Outline")
	var outline: OutlineAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get Images for\(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline)) { outline in
            DisplayRepresentation(
                title: "Get Images for\(outline!)",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        // TODO: Place your refactored intent handler code here.
		return .result(value: IntentFile(fileURL: URL(string: "")!))
    }
}



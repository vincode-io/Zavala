//
//  RemoveOutline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct RemoveOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "RemoveOutlineIntent"
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.remove-outline", comment: "Intent title: Remove Outline")
    static let description = IntentDescription(LocalizedStringResource("intent.description.remove-outline", comment: "Intent title: Deletes an Outline"))
	
    @Parameter(title: LocalizedStringResource("intent.parameter.outline", comment: "Intent parameter: Outline"))
	var outline: OutlineAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.remove-\(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline)) { outline in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.remove-\(outline)", comment: "Intent prediction: Remove <Outline>"),
                subtitle: nil
            )
        }
    }

    func perform() async throws -> some IntentResult {
		await resume()
		
		guard let outline = await findOutline(outline) else {
			await suspend()
			throw ZavalaAppIntentError.outlineNotFound
		}
		
		await outline.account?.deleteDocument(.outline(outline))
		
		await suspend()
		return .result()
    }
	
}



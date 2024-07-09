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
    static let title: LocalizedStringResource = "Remove Outline"
    static let description = IntentDescription("Deletes an Outline.")

    @Parameter(title: "Outline")
	var outline: OutlineAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Remove \(\.$outline)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline)) { outline in
            DisplayRepresentation(
                title: "Remove \(outline)",
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
		
		await outline.account?.deleteDocument(.outline(outline))
		
		await suspend()
		return .result()
    }
	
}



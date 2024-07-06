//
//  RemoveRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct RemoveRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "RemoveRowsIntent"
    static let title: LocalizedStringResource = "Remove Rows"
    static let description = IntentDescription("Delete the specified Rows.")

    @Parameter(title: "Rows")
	var rows: [RowAppEntity]?

    static var parameterSummary: some ParameterSummary {
        Summary("Remove \(\.$rows)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$rows)) { rows in
            DisplayRepresentation(
                title: "Remove \(rows!, format: .list(type: .and))",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        // TODO: Place your refactored intent handler code here.
        return .result()
    }
}



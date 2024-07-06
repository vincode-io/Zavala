//
//  MoveRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct MoveRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "MoveRowsIntent"
    static let title: LocalizedStringResource = "Move Rows"
    static let description = IntentDescription("Move Rows in or between Outlines.")

    @Parameter(title: "Rows")
	var rows: [RowAppEntity]?

    @Parameter(title: "Entity ID")
	var entityID: EntityIDAppEntity?

    @Parameter(title: "Destination")
    var destination: RowDestinationAppEnum?

    static var parameterSummary: some ParameterSummary {
        Summary("Move \(\.$rows) to \(\.$entityID) at \(\.$destination)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$rows, \.$entityID, \.$destination)) { rows, entityID, destination in
            DisplayRepresentation(
                title: "Move \(rows!, format: .list(type: .and)) to \(entityID!) at \(destination!)",
                subtitle: ""
            )
        }
    }

	func perform() async throws -> some IntentResult & ReturnsValue<RowAppEntity> {
        // TODO: Place your refactored intent handler code here.
		return .result(value: RowAppEntity(/* fill in result initializer here */))
    }
}

private extension IntentDialog {
    static func destinationParameterDisambiguationIntro(count: Int, destination: RowDestinationAppEnum) -> Self {
        "There are \(count) options matching ‘\(destination)’."
    }
    static func destinationParameterConfirmation(destination: RowDestinationAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(destination)’?"
    }
    static func destinationParameterRequired(destination: RowDestinationAppEnum) -> Self {
        "The \(destination) is required."
    }
}


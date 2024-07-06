//
//  AddRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct AddRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "AddRowsIntent"
    static let title: LocalizedStringResource = "Add Rows"
    static let description = IntentDescription("Add Rows to an Outline.")

    @Parameter(title: "Entity ID")
	var entityID: EntityIDAppEntity?

    @Parameter(title: "Destination")
    var destination: RowDestinationAppEnum?

    @Parameter(title: "Topics")
    var topics: [String]?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$topics) to \(\.$entityID) at \(\.$destination)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$entityID, \.$destination, \.$topics)) { entityID, destination, topics in
            DisplayRepresentation(
                title: "Add \(topics!, format: .list(type: .and)) to \(entityID!) at \(destination!)",
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
    static func topicsParameterPrompt(topics: String) -> Self {
        "What are the \(topics) you would like add?"
    }
    static func topicsParameterRequired(topics: String) -> Self {
        "At least one \(topics) is required."
    }
}


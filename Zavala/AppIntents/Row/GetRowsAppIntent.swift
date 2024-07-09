//
//  GetRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct GetRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetRowsIntent"
    static let title: LocalizedStringResource = "Get Rows"
    static let description = IntentDescription("Get Rows from an Outline.")

    @Parameter(title: "Entity ID")
	var entityID: EntityID

    @Parameter(title: "Search")
    var search: String?

    @Parameter(title: "Regular Expression", default: true)
    var regularExpression: Bool?

    @Parameter(title: "Start Depth", default: 1)
    var startDepth: Int?

    @Parameter(title: "End Depth", default: 1)
    var endDepth: Int?

    @Parameter(title: "Completion State")
    var completionState: RowCompletionStateAppEnum?

    @Parameter(title: "Expanded State")
    var expandedState: RowExpandedStateAppEnum?

    @Parameter(title: "Excluded Rows")
	var excludedRows: [EntityID]?

    static var parameterSummary: some ParameterSummary {
        Summary("Get Rows matching \(\.$search) starting at \(\.$entityID)") {
            \.$regularExpression
            \.$completionState
            \.$expandedState
            \.$excludedRows
            \.$startDepth
            \.$endDepth
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$entityID, \.$search, \.$regularExpression, \.$completionState, \.$expandedState, \.$excludedRows, \.$startDepth, \.$endDepth)) { entityID, search, regularExpression, completionState, expandedState, excludedRows, startDepth, endDepth in
            DisplayRepresentation(
                title: "Get Rows matching \(search!) starting at \(entityID)",
                subtitle: ""
            )
        }
    }

	func perform() async throws -> some IntentResult & ReturnsValue<[RowAppEntity]> {
        // TODO: Place your refactored intent handler code here.
		return .result(value: [RowAppEntity(/* fill in result initializer here */)])
    }
}

private extension IntentDialog {
    static func searchParameterPrompt(search: String) -> Self {
        "What is the\(search)term?"
    }
    static func completionStateParameterDisambiguationIntro(count: Int, completionState: RowCompletionStateAppEnum) -> Self {
        "There are \(count) options matching ‘\(completionState)’."
    }
    static func completionStateParameterConfirmation(completionState: RowCompletionStateAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(completionState)’?"
    }
    static func expandedStateParameterDisambiguationIntro(count: Int, expandedState: RowExpandedStateAppEnum) -> Self {
        "There are \(count) options matching ‘\(expandedState)’."
    }
    static func expandedStateParameterConfirmation(expandedState: RowExpandedStateAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(expandedState)’?"
    }
    static var responseRowRequired: Self {
        "You must specify a Row for this Destination."
    }
}


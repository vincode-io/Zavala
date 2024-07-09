//
//  CopyRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct CopyRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "CopyRowsIntent"
    static let title: LocalizedStringResource = "Copy Rows"
    static let description = IntentDescription("Copy Rows in or between Outlines.")

    @Parameter(title: "Rows")
	var rows: [RowAppEntity]

    @Parameter(title: "Entity ID")
	var entityID: EntityID

    @Parameter(title: "Destination")
    var destination: RowDestinationAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Copy \(\.$rows) to \(\.$entityID) at \(\.$destination)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$rows, \.$entityID, \.$destination)) { rows, entityID, destination in
            DisplayRepresentation(
                title: "Copy \(rows, format: .list(type: .and)) to \(entityID) at \(destination)",
                subtitle: ""
            )
        }
    }

	func perform() async throws -> some IntentResult & ReturnsValue<[RowAppEntity]> {
        // TODO: Place your refactored intent handler code here.
		return .result(value: [RowAppEntity(/* fill in result initializer here */)])
    }
}

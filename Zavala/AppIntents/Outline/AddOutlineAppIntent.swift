//
//  AddOutline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct AddOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "AddOutlineIntent"
    static let title: LocalizedStringResource = "Add Outline"
    static let description = IntentDescription("Adds an Outline.")

    @Parameter(title: "Account Type")
	var accountType: AccountTypeAppEnum?

    @Parameter(title: "Title")
    var title: String?

    @Parameter(title: "Tag Names")
    var tagNames: [String]?

    static var parameterSummary: some ParameterSummary {
        Summary("Add Outline titled\(\.$title)to\(\.$accountType)") {
            \.$tagNames
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$title, \.$tagNames, \.$accountType)) { title, tagNames, accountType in
            DisplayRepresentation(
                title: "Add Outline titled\(title!)to\(accountType!)",
                subtitle: ""
            )
        }
    }

	func perform() async throws -> some IntentResult & ReturnsValue<OutlineAppEntity> {
        // TODO: Place your refactored intent handler code here.
        return .result(value: OutlineAppEntity(/* fill in result initializer here */))
    }
}

private extension IntentDialog {
	static func accountTypeParameterDisambiguationIntro(count: Int, accountType: AccountTypeAppEnum) -> Self {
        "There are \(count) options matching ‘\(accountType)’."
    }
    static func accountTypeParameterConfirmation(accountType: AccountTypeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(accountType)’?"
    }
    static func titleParameterPrompt(title: String) -> Self {
        "Enter the \(title)of this Outline."
    }
    static func tagNamesParameterPrompt(tagNames: String) -> Self {
        "Enter the \(tagNames)for this Outline"
    }
}


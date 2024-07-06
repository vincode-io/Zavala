//
//  Import.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct ImportAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "ImportIntent"
    static let title: LocalizedStringResource = "Import"
    static let description = IntentDescription("Import an outline.")

    @Parameter(title: "Input File")
    var inputFile: IntentFile?

    @Parameter(title: "Input Images")
    var inputImages: [IntentFile]?

    @Parameter(title: "Import Type")
	var importType: ImportTypeAppEnum?

    @Parameter(title: "Account Type")
	var accountType: AccountTypeAppEnum?

    static var parameterSummary: some ParameterSummary {
        Summary("Import the \(\.$importType) \(\.$inputFile) into \(\.$accountType)") {
            \.$inputImages
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$inputFile, \.$importType, \.$accountType, \.$inputImages)) { inputFile, importType, accountType, inputImages in
            DisplayRepresentation(
                title: "Import the\(importType!)\(inputFile!)into\(accountType!)",
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
    static var inputFileParameterPrompt: Self {
        "Please supply the Input File."
    }
	static func importTypeParameterDisambiguationIntro(count: Int, importType: ImportTypeAppEnum) -> Self {
        "There are \(count) options matching ‘\(importType)’."
    }
	static func importTypeParameterConfirmation(importType: ImportTypeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(importType)’?"
    }
    static var importTypeParameterRequired: Self {
        "The Import Type is required."
    }
	static func accountTypeParameterDisambiguationIntro(count: Int, accountType: AccountTypeAppEnum) -> Self {
        "There are \(count) options matching ‘\(accountType)’."
    }
	static func accountTypeParameterConfirmation(accountType: AccountTypeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(accountType)’?"
    }
    static var accountTypeParameterRequired: Self {
        "The Account Type is required."
    }
}


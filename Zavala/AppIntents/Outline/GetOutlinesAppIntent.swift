//
//  GetOutlines.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct GetOutlinesAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetOutlinesIntent"
    static let title: LocalizedStringResource = "Get Outlines"
    static let description = IntentDescription("Get outlines based on search criteria.")

    @Parameter(title: "Search")
    var search: String?

    @Parameter(title: "Account Type")
	var accountType: AccountTypeAppEnum?

    @Parameter(title: "Tag", optionsProvider: tagStringOptionsProvider())
    var tagNames: [String]?

    struct tagStringOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            // TODO: Return possible options here.
            return []
        }
    }

    @Parameter(title: "Outline", optionsProvider: outlineStringOptionsProvider())
    var outlineNames: [String]?

    struct outlineStringOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            // TODO: Return possible options here.
            return []
        }
    }

    @Parameter(title: "Created Start Date")
    var createdStartDate: DateComponents?

    @Parameter(title: "Created End Date")
    var createdEndDate: DateComponents?

    @Parameter(title: "Updated Start Date")
    var updatedStartDate: DateComponents?

    @Parameter(title: "Updated End Date")
    var updatedEndDate: DateComponents?

    static var parameterSummary: some ParameterSummary {
        Summary("Get Outlines") {
            \.$accountType
            \.$outlineNames
            \.$tagNames
            \.$createdStartDate
            \.$createdEndDate
            \.$updatedStartDate
            \.$updatedEndDate
            \.$search
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$accountType, \.$outlineNames, \.$tagNames, \.$createdStartDate, \.$createdEndDate, \.$updatedStartDate, \.$updatedEndDate, \.$search)) { accountType, outlineNames, tagNames, createdStartDate, createdEndDate, updatedStartDate, updatedEndDate, search in
            DisplayRepresentation(
                title: "Get Outlines",
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
    static func searchParameterPrompt(search: String) -> Self {
        "What is the \(search)criteria?"
    }
	static func accountTypeParameterDisambiguationIntro(count: Int, accountType: AccountTypeAppEnum) -> Self {
        "There are \(count) options matching ‘\(accountType)’."
    }
	static func accountTypeParameterConfirmation(accountType: AccountTypeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(accountType)’?"
    }
    static func tagNamesParameterConfiguration(tagNames: String) -> Self {
        "Select a\(tagNames)"
    }
    static func tagNamesParameterPrompt(tagNames: String) -> Self {
        "What is the \(tagNames)?"
    }
    static func tagNamesParameterDisambiguationIntro(count: Int, tagNames: String) -> Self {
        "There are \(count) options matching ‘\(tagNames)’."
    }
    static func tagNamesParameterConfirmation(tagNames: String) -> Self {
        "Just to confirm, you wanted ‘\(tagNames)’?"
    }
    static func outlineNamesParameterConfiguration(outlineNames: String) -> Self {
        "Select an \(outlineNames)"
    }
    static func outlineNamesParameterPrompt(outlineNames: String) -> Self {
        "What is the \(outlineNames)?"
    }
    static func createdStartDateParameterPrompt(createdStartDate: DateComponents) -> Self {
		"What is the \(String(describing: createdStartDate))?"
    }
    static func createdEndDateParameterPrompt(createdEndDate: DateComponents) -> Self {
        "What is the \(String(describing: createdEndDate))?"
    }
    static func updatedStartDateParameterPrompt(updatedStartDate: DateComponents) -> Self {
        "What is the \(String(describing: updatedStartDate))?"
    }
    static func updatedEndDateParameterPrompt(updatedEndDate: DateComponents) -> Self {
        "What is the \(String(describing: updatedEndDate))?"
    }
}


//
//  EditOutline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct EditOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "EditOutlineIntent"
    static let title: LocalizedStringResource = "Edit Outline"
    static let description = IntentDescription("Update the details of an Outline.")

    @Parameter(title: "Outline")
	var outline: OutlineAppEntity?

    @Parameter(title: "Detail")
    var detail: OutlineDetailAppEnum?

    @Parameter(title: "Title")
    var title: String?

    @Parameter(title: "Owner Name")
    var ownerName: String?

    @Parameter(title: "Owner Email")
    var ownerEmail: String?

    @Parameter(title: "Owner URL")
    var ownerURL: String?

    static var parameterSummary: some ParameterSummary {
        Switch(\.$detail) {
            Case(.title) {
                Summary("Set \(\.$detail) of \(\.$outline) to \(\.$title)")
            }
            Case(.ownerName) {
                Summary("Set \(\.$detail) of \(\.$outline) to \(\.$ownerName)")
            }
            Case(.ownerEmail) {
                Summary("Set \(\.$detail) of \(\.$outline) to \(\.$ownerEmail)")
            }
            Case(.ownerURL) {
                Summary("Set \(\.$detail) of \(\.$outline) to \(\.$ownerURL)")
            }
            DefaultCase {
                Summary("Set \(\.$detail) of \(\.$outline)")
            }
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$ownerName)) { outline, detail, ownerName in
            DisplayRepresentation(
                title: "Set \(detail!)of \(outline!)to \(ownerName!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$ownerURL)) { outline, detail, ownerURL in
            DisplayRepresentation(
                title: "Set \(detail!)of \(outline!)to \(ownerURL!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$title)) { outline, detail, title in
            DisplayRepresentation(
                title: "Set\(detail!)of\(outline!)to\(title!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$ownerEmail)) { outline, detail, ownerEmail in
            DisplayRepresentation(
                title: "Set\(detail!)of\(outline!)to \(ownerEmail!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail)) { outline, detail in
            DisplayRepresentation(
                title: "Set \(detail!)of \(outline!)",
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
    static func detailParameterDisambiguationIntro(count: Int, detail: OutlineDetailAppEnum) -> Self {
        "There are \(count) options matching ‘\(detail)’."
    }
    static func detailParameterConfirmation(detail: OutlineDetailAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(detail)’?"
    }
    static func titleParameterPrompt(title: String) -> Self {
        "What is the \(title)"
    }
    static func ownerNameParameterPrompt(ownerName: String) -> Self {
        "What is the \(ownerName)"
    }
    static func ownerEmailParameterPrompt(ownerEmail: String) -> Self {
        "What is the \(ownerEmail)"
    }
    static var ownerURLParameterPrompt: Self {
        "What is the ownerURL"
    }
}


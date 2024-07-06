//
//  EditRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct EditRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "EditRowsIntent"
    static let title: LocalizedStringResource = "Edit Rows"
    static let description = IntentDescription("Update the details of a Row.")

    @Parameter(title: "Rows")
	var rows: [RowAppEntity]?

    @Parameter(title: "Detail")
    var detail: RowDetailAppEnum?

    @Parameter(title: "Topic")
    var topic: String?

    @Parameter(title: "Note")
    var note: String?

    @Parameter(title: "Complete")
    var complete: Bool?

    @Parameter(title: "Expanded")
    var expanded: Bool?

    static var parameterSummary: some ParameterSummary {
        Switch(\.$detail) {
            Case(.topic) {
                Summary("Set \(\.$detail) of \(\.$rows) to \(\.$topic)")
            }
            Case(.note) {
                Summary("Set \(\.$detail) of \(\.$rows) to \(\.$note)")
            }
            Case(.complete) {
                Summary("Set \(\.$detail) of \(\.$rows) to \(\.$complete)")
            }
            Case(.expanded) {
                Summary("Set \(\.$detail) of \(\.$rows) to \(\.$expanded)")
            }
            DefaultCase {
                Summary("Set \(\.$detail) of \(\.$rows)")
            }
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$topic)) { rows, detail, topic in
            DisplayRepresentation(
                title: "Set \(detail!) of \(rows!, format: .list(type: .and)) to \(topic!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$note)) { rows, detail, note in
            DisplayRepresentation(
                title: "Set \(detail!) of \(rows!, format: .list(type: .and)) to \(note!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$complete)) { rows, detail, complete in
            DisplayRepresentation(
                title: "Set \(detail!) of \(rows!, format: .list(type: .and)) to \(String(describing: complete!))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail, \.$expanded)) { rows, detail, expanded in
            DisplayRepresentation(
                title: "Set \(detail!) of \(rows!, format: .list(type: .and)) to \(String(describing: expanded!))",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$rows, \.$detail)) { rows, detail in
            DisplayRepresentation(
                title: "Set \(detail!) of \(rows!, format: .list(type: .and))",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        // TODO: Place your refactored intent handler code here.
        return .result()
    }
}

private extension IntentDialog {
    static func detailParameterDisambiguationIntro(count: Int, detail: RowDetailAppEnum) -> Self {
        "There are \(count) options matching ‘\(detail)’."
    }
    static func detailParameterConfirmation(detail: RowDetailAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(detail)’?"
    }
	static func topicParameterPrompt(rows: RowAppEntity, topic: String) -> Self {
        "What is the \(rows) \(topic)"
    }
	static func noteParameterPrompt(rows: RowAppEntity, topic: String) -> Self {
        "What is the \(rows) \(topic)"
    }
    static func completeParameterPrompt(complete: Bool) -> Self {
		"Mark complete as \(String(describing: complete))"
    }
    static func expandedParameterPrompt(expanded: Bool) -> Self {
		"Mark expanded as \(String(describing: expanded))"
    }
}


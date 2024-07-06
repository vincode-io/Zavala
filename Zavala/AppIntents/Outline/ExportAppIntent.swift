//
//  Export.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct ExportAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "ExportIntent"
    static let title: LocalizedStringResource = "Export"
    static let description = IntentDescription("Export the outline in various formats.")

    @Parameter(title: "Outline")
	var outline: OutlineAppEntity?

    @Parameter(title: "Export Type")
    var exportType: ExportTypeAppEnum?

    @Parameter(title: "Export Link Type", default: .zavalaLinks)
    var exportLinkType: ExportLinkTypeAppEnum?

    static var parameterSummary: some ParameterSummary {
        Summary("Export the\(\.$outline)as \(\.$exportType)using \(\.$exportLinkType)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline, \.$exportType, \.$exportLinkType)) { outline, exportType, exportLinkType in
            DisplayRepresentation(
                title: "Export the\(outline!)as \(exportType!)using \(exportLinkType!)",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        // TODO: Place your refactored intent handler code here.
		return .result(value: IntentFile(fileURL: URL(string: "")!))
    }
}

private extension IntentDialog {
	static func exportTypeParameterDisambiguationIntro(count: Int, exportType: ExportTypeAppEnum) -> Self {
        "There are \(count) options matching ‘\(exportType)’."
    }
	static func exportTypeParameterConfirmation(exportType: ExportTypeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(exportType)’?"
    }
    static func exportLinkTypeParameterDisambiguationIntro(count: Int, exportLinkType: ExportLinkTypeAppEnum) -> Self {
        "There are \(count) options matching ‘\(exportLinkType)’."
    }
    static func exportLinkTypeParameterConfirmation(exportLinkType: ExportLinkTypeAppEnum) -> Self {
        "Just to confirm, you wanted ‘\(exportLinkType)’?"
    }
}


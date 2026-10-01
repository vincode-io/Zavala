//
//  EditOutline.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

struct EditOutlineAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "EditOutlineIntent"
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.edit-outline", comment: "Intent title: Edit Outline")
    static let description = IntentDescription(LocalizedStringResource("intent.description.edit-outline", comment: "Intent description: Update the details of an Outline."))

    @Parameter(title: LocalizedStringResource("intent.parameter.outline", comment: "Intent parameter: Outline"))
	var outline: OutlineAppEntity

    @Parameter(title: LocalizedStringResource("intent.parameter.detail", comment: "Intent parameter: Detail"))
    var detail: OutlineDetailAppEnum

    @Parameter(title: LocalizedStringResource("intent.parameter.title", comment: "Intent Parameter: Title"))
    var title: String?

    @Parameter(title: LocalizedStringResource("intent.parameter.owner-name", comment: "Intent parameter: Owner Name"))
    var ownerName: String?

    @Parameter(title: LocalizedStringResource("intent.parameter.owner-email", comment: "Intent parameter: Owner Email"))
    var ownerEmail: String?

    @Parameter(title: LocalizedStringResource("intent.parameter.owner-url", comment: "Intent parameter: Owner URL"))
    var ownerURL: String?

    static var parameterSummary: some ParameterSummary {
        Switch(\.$detail) {
            Case(.title) {
                Summary("intent.summary.set-\(\.$detail)-of-\(\.$outline)-to-\(\.$title)")
            }
            Case(.ownerName) {
                Summary("intent.summary.set-\(\.$detail)-of-\(\.$outline)-to-\(\.$ownerName)")
            }
            Case(.ownerEmail) {
                Summary("intent.summary.set-\(\.$detail)-of-\(\.$outline)-to-\(\.$ownerEmail)")
            }
            Case(.ownerURL) {
                Summary("intent.summary.set-\(\.$detail)-of-\(\.$outline)-to-\(\.$ownerURL)")
            }
            DefaultCase {
                Summary("intent.summary.set-\(\.$detail)-of-\(\.$outline)")
            }
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$ownerName)) { outline, detail, ownerName in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.set-detail-\(detail)-outline-\(outline)-ownerName-\(ownerName!)", comment: "Intent prediction: Set <detail> of <outline> to <owner name>"),
                subtitle: nil
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$ownerURL)) { outline, detail, ownerURL in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.set-detail-\(detail)-outline-\(outline)-ownerURL-\(ownerURL!)", comment: "Intent prediction: Set <detail> of <outline> to <owner URL>"),
                subtitle: nil
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$title)) { outline, detail, title in
            DisplayRepresentation(
                title: LocalizedStringResource("intent.prediction.set-detail-\(detail)-outline-\(outline)-title-\(title!)", comment: "Intent prediction: Set <detail> of <outline> to <title>"),
                subtitle: nil
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$ownerEmail)) { outline, detail, ownerEmail in
            DisplayRepresentation(
                title: LocalizedStringResource("intent.prediction.set-detail-\(detail)-outline-\(outline)-ownerEmail-\(ownerEmail!)", comment: "Intent prediction: Set <detail> of <outline> to <owner Email>"),
                subtitle: nil
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail)) { outline, detail in
            DisplayRepresentation(
                title: LocalizedStringResource("intent.prediction.set-detail-\(detail)-outline-\(outline)", comment: "Intent prediction: Set <detail> of <outline>"),
                subtitle: nil
            )
        }
    }

	@MainActor
	func perform() async throws -> some IntentResult & ReturnsValue<OutlineAppEntity> {
		resume()
		
		guard let outline = findOutline(outline) else {
			await suspend()
			throw ZavalaAppIntentError.outlineNotFound
		}

		guard !(outline.isLocked ?? false) else {
			await suspend()
			throw ZavalaAppIntentError.outlineIsLocked
		}

		switch detail {
		case .title:
			outline.update(title: title)
		case .ownerName:
			outline.update(ownerName: ownerName)
		case .ownerEmail:
			outline.update(ownerEmail: ownerEmail)
		case .ownerURL:
			outline.update(ownerURL: ownerURL)
		}

		DocumentIndexer.updateIndex(for: .outline(outline))

		await suspend()
		return .result(value: OutlineAppEntity(outline: outline))
    }
}

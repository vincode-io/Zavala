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
    static let title: LocalizedStringResource = "Edit Outline"
    static let description = IntentDescription("Update the details of an Outline.")

    @Parameter(title: "Outline")
	var outline: OutlineAppEntity

    @Parameter(title: "Detail")
    var detail: OutlineDetailAppEnum

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
                title: "Set \(detail) of \(outline) to \(ownerName!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$ownerURL)) { outline, detail, ownerURL in
            DisplayRepresentation(
                title: "Set \(detail) of \(outline) to \(ownerURL!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$title)) { outline, detail, title in
            DisplayRepresentation(
                title: "Set\(detail) of\(outline) to \(title!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail, \.$ownerEmail)) { outline, detail, ownerEmail in
            DisplayRepresentation(
                title: "Set\(detail) of\(outline) to \(ownerEmail!)",
                subtitle: ""
            )
        }
        IntentPrediction(parameters: (\.$outline, \.$detail)) { outline, detail in
            DisplayRepresentation(
                title: "Set \(detail) of \(outline)",
                subtitle: ""
            )
        }
    }

	func perform() async throws -> some IntentResult & ReturnsValue<OutlineAppEntity> {
		await resume()
		
		guard let outline = await findOutline(outline) else {
			await suspend()
			throw ZavalaAppIntentError.unexpectedError
		}
		
		switch detail {
		case .title:
			await outline.update(title: title)
		case .ownerName:
			await outline.update(ownerName: ownerName)
		case .ownerEmail:
			await outline.update(ownerEmail: ownerEmail)
		case .ownerURL:
			await outline.update(ownerURL: ownerURL)
		}
		
		await suspend()
		return await .result(value: OutlineAppEntity(outline: outline))
    }
}

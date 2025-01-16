//
//  RemoveRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct RemoveRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "RemoveRowsIntent"
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.remove-rows", comment: "Remove Rows")
    static let description = IntentDescription(LocalizedStringResource("intent.descrption.delete-rows", comment: "Delete the specified Rows."))

    @Parameter(title: LocalizedStringResource("intent.parameter.rows", comment: "Rows"))
	var rows: [RowAppEntity]

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.remove-\(\.$rows)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$rows)) { rows in
            DisplayRepresentation(
                title: LocalizedStringResource("intent.prediction.remove-\(rows, format: .list(type: .and))", comment: "Remove <rows>"),
                subtitle: nil
            )
        }
    }

	@MainActor
	func perform() async throws -> some IntentResult {
		resume()
		
		var outlines = Set<Outline>()
		
		let inputRows: [Row] = rows
			.compactMap { $0.entityID }
			.compactMap {
				if let rowOutline = appDelegate.accountManager.findDocument($0)?.outline {
					rowOutline.load()
					outlines.insert(rowOutline)
					return rowOutline.findRow(id: $0.rowUUID)
				}
				return nil
			}
		
		let groupedInputRows = Dictionary(grouping: inputRows, by: { $0.outline })
		
		for outline in groupedInputRows.keys {
			if let outline, let deleteRows = groupedInputRows[outline] {
				outline.deleteRows(deleteRows)
			}
		}
		
		for outline in outlines {
			await outline.unload()
		}
		
		await suspend()
		return .result()
	}
}



//
//  CopyRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct CopyRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
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

	@MainActor
	func perform() async throws -> some IntentResult & ReturnsValue<[RowAppEntity]> {
		resume()
		
		guard let outline = findOutline(entityID) else {
			await suspend()
			throw ZavalaAppIntentError.outlineNotFound
		}
		
		var outlines = Set<Outline>()
		outline.load()
		outlines.insert(outline)
		
		guard let rowContainer = outline.findRowContainer(entityID: entityID) else {
			await outline.unload()
			await suspend()
			throw ZavalaAppIntentError.rowContainerNotFound
		}
		
		let rows: [Row] = self.rows
			.compactMap { $0.entityID }
			.compactMap {
				if let rowOutline = appDelegate.accountManager.findDocument($0)?.outline {
					rowOutline.load()
					outlines.insert(rowOutline)
					return rowOutline.findRow(id: $0.rowUUID)
				}
				return nil
			}
		
		for row in rows {
			let rowGroup = RowGroup(row)
			let attachedRow = rowGroup.attach(to: outline)

			switch destination {
			case .insideAtStart:
				outline.createRowsInsideAtStart([attachedRow], afterRowContainer: rowContainer)
			case .insideAtEnd:
				outline.createRowsInsideAtEnd([attachedRow], afterRowContainer: rowContainer)
			case .outside:
				if let afterRow = rowContainer as? Row {
					outline.createRowsOutside([attachedRow], afterRow: afterRow)
				}
			case .directlyAfter:
				if let afterRow = rowContainer as? Row {
					outline.createRowsDirectlyAfter([attachedRow], afterRow: afterRow)
				}
			}
		}

		for outline in outlines {
			await outline.unload()
		}
		
		await suspend()
		return .result(value: rows.map({RowAppEntity(row: $0)}))
    }
}

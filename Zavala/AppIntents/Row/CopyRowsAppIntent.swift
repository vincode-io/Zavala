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
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.copy-rows", comment: "Copy Rows")
    static let description = IntentDescription(LocalizedStringResource("intent.descrption.copy-rows-outlines", comment: "Copy Rows in or between Outlines"))

    @Parameter(title: LocalizedStringResource("intent.parameter.rows", comment: "Rows"))
	var rows: [RowAppEntity]

    @Parameter(title: LocalizedStringResource("intent.parameter.entity-id", comment: "Entity ID"))
	var entityID: EntityID

    @Parameter(title: LocalizedStringResource("intent.parameter.destination", comment: "Destination"))
    var destination: RowDestinationAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.copy-\(\.$rows)-to-\(\.$entityID)-at-\(\.$destination)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$rows, \.$entityID, \.$destination)) { rows, entityID, destination in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.copy-\(rows, format: .list(type: .and))-to-\(entityID)-at-\(destination)", comment: "Copy <rows> to <entityID> at <destination>)"),
                subtitle: nil
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
		
		var copiedRows = [Row]()
		
		for row in rows {
			let rowGroup = RowGroup(row)
			let attachedRow = rowGroup.attach(to: outline)

			copiedRows.append(attachedRow)
			
			switch destination {
			case .insideAtStart:
				outline.createRowsInsideAtStart([attachedRow], afterRowContainer: rowContainer)
			case .insideAtEnd:
				outline.createRowsInsideAtEnd([attachedRow], afterRowContainer: rowContainer)
			case .outside:
				if let afterRow = rowContainer as? Row {
					outline.createRowsOutside([attachedRow], afterRow: afterRow)
				} else {
					try await suspendUnloadAndThrow(outlines: outlines)
				}
			case .directlyBefore:
				if let beforeRow = rowContainer as? Row {
					outline.createRows([attachedRow], beforeRow: beforeRow, moveCursor: false)
				} else {
					try await suspendUnloadAndThrow(outlines: outlines)
				}
			case .directlyAfter:
				if let afterRow = rowContainer as? Row {
					outline.createRowsDirectlyAfter([attachedRow], afterRow: afterRow)
				} else {
					try await suspendUnloadAndThrow(outlines: outlines)
				}
			}
		}

		for outline in outlines {
			await outline.unload()
		}
		
		await suspend()
		return .result(value: copiedRows.map({RowAppEntity(row: $0)}))
    }
	
	private func suspendUnloadAndThrow(outlines: Set<Outline>) async throws {
		for outline in outlines {
			await outline.unload()
		}
		await suspend()
		throw ZavalaAppIntentError.invalidDestinationForOutline
	}
	
}

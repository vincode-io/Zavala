//
//  MoveRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct MoveRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "MoveRowsIntent"
    static let title: LocalizedStringResource = "Move Rows"
    static let description = IntentDescription("Move Rows in or between Outlines.")

    @Parameter(title: "Rows")
	var rows: [RowAppEntity]

    @Parameter(title: "Entity ID")
	var entityID: EntityID

    @Parameter(title: "Destination")
    var destination: RowDestinationAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Move \(\.$rows) to \(\.$entityID) at \(\.$destination)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$rows, \.$entityID, \.$destination)) { rows, entityID, destination in
            DisplayRepresentation(
                title: "Move \(rows, format: .list(type: .and)) to \(entityID) at \(destination)",
                subtitle: ""
            )
        }
    }

	@MainActor
	func perform() async throws -> some IntentResult & ReturnsValue<[RowAppEntity]> {
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

		var intraOutlineMoves = [Row]()
		var interOutlineMoves = [Row]()

		let inputRows: [Row] = rows
			.compactMap { $0.entityID }
			.compactMap {
				if let rowOutline = AccountManager.shared.findDocument($0)?.outline {
					rowOutline.load()
					outlines.insert(rowOutline)
					return rowOutline.findRow(id: $0.rowUUID)
				}
				return nil
			}
		
		for inputRow in inputRows {
			if inputRow.outline == outline {
				intraOutlineMoves.append(inputRow)
			} else {
				interOutlineMoves.append(inputRow)
			}
		}
		
		var movedRows = intraOutlineMoves
		
		if !intraOutlineMoves.isEmpty {
			switch destination {
			case .insideAtStart:
				outline.moveRowsInsideAtStart(intraOutlineMoves, afterRowContainer: rowContainer)
			case .insideAtEnd:
				outline.moveRowsInsideAtEnd(intraOutlineMoves, afterRowContainer: rowContainer)
			case .outside:
				if let afterRow = rowContainer as? Row {
					outline.moveRowsOutside(intraOutlineMoves, afterRow: afterRow)
				}
			case .directlyAfter:
				if let afterRow = rowContainer as? Row {
					outline.moveRowsDirectlyAfter(intraOutlineMoves, afterRow: afterRow)
				}
			}
		}
		
		for interOutlineMove in interOutlineMoves {
			guard let sourceOutline = interOutlineMove.outline else {
				continue
			}

			let rowGroup = RowGroup(interOutlineMove)
			let attachedRow = rowGroup.attach(to: outline)
			movedRows.append(attachedRow)
			
			switch destination {
			case .insideAtStart:
				sourceOutline.deleteRows([interOutlineMove])
				outline.createRowsInsideAtStart([attachedRow], afterRowContainer: rowContainer)
			case .insideAtEnd:
				sourceOutline.deleteRows([interOutlineMove])
				outline.createRowsInsideAtEnd([attachedRow], afterRowContainer: rowContainer)
			case .outside:
				if let afterRow = rowContainer as? Row {
					sourceOutline.deleteRows([interOutlineMove])
					outline.createRowsOutside([attachedRow], afterRow: afterRow)
				}
			case .directlyAfter:
				if let afterRow = rowContainer as? Row {
					sourceOutline.deleteRows([interOutlineMove])
					outline.createRowsDirectlyAfter([attachedRow], afterRow: afterRow)
				}
			}
		}

		for outline in outlines {
			await outline.unload()
		}
		
		await suspend()
		return .result(value: movedRows.map({RowAppEntity(row: $0)}))
    }
}

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
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.move-rows", comment: "Move Rows")
    static let description = IntentDescription(LocalizedStringResource("intent.descrption.move-rows-outlines", comment: "Move Rows in or between Outlines"))

    @Parameter(title: LocalizedStringResource("intent.parameter.rows", comment: "Rows"))
	var rows: [RowAppEntity]

    @Parameter(title: LocalizedStringResource("intent.parameter.entity-id", comment: "Entity ID"))
	var entityID: EntityID

    @Parameter(title: LocalizedStringResource("intent.parameter.destination", comment: "Destination"))
    var destination: RowDestinationAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.move-\(\.$rows)-to-\(\.$entityID)-at-\(\.$destination)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$rows, \.$entityID, \.$destination)) { rows, entityID, destination in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.move-\(rows, format: .list(type: .and))-to-\(entityID)-at-\(destination)", comment: "Move <rows> to <entityID> at <destination>"),
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

		var intraOutlineMoves = [Row]()
		var interOutlineMoves = [Row]()

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
				} else {
					try await suspendUnloadAndThrow(outlines: outlines)
				}
			case .directlyBefore:
				if let beforeRow = rowContainer as? Row {
					outline.moveRowsDirectlyBefore(intraOutlineMoves, beforeRow: beforeRow)
				} else {
					try await suspendUnloadAndThrow(outlines: outlines)
				}
			case .directlyAfter:
				if let afterRow = rowContainer as? Row {
					outline.moveRowsDirectlyAfter(intraOutlineMoves, afterRow: afterRow)
				} else {
					try await suspendUnloadAndThrow(outlines: outlines)
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
				} else {
					try await suspendUnloadAndThrow(outlines: outlines)
				}
			case .directlyBefore:
				if let beforeRow = rowContainer as? Row {
					sourceOutline.deleteRows([interOutlineMove])
					outline.createRows([attachedRow], beforeRow: beforeRow, moveCursor: false)
				} else {
					try await suspendUnloadAndThrow(outlines: outlines)
				}
			case .directlyAfter:
				if let afterRow = rowContainer as? Row {
					sourceOutline.deleteRows([interOutlineMove])
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
		return .result(value: movedRows.map({RowAppEntity(row: $0)}))
    }
	
	private func suspendUnloadAndThrow(outlines: Set<Outline>) async throws {
		for outline in outlines {
			await outline.unload()
		}
		await suspend()
		throw ZavalaAppIntentError.invalidDestinationForOutline
	}
	
}

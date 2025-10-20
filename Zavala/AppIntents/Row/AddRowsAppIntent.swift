//
//  AddRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct AddRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "AddRowsIntent"
	static let title: LocalizedStringResource = LocalizedStringResource("intent.title.add-rows", comment: "Add Rows")
	static let description = IntentDescription(LocalizedStringResource("intent.descrption.add-rows-to-outline", comment: "Add Rows to Outline"))

    @Parameter(title: LocalizedStringResource("intent.parameter.entity-id", comment: "Entity ID"))
	var entityID: EntityID

    @Parameter(title: LocalizedStringResource("intent.parameter.destination", comment: "Destination"))
    var destination: RowDestinationAppEnum

    @Parameter(title: LocalizedStringResource("intent.parameter.topics", comment: "Topics"))
    var topics: [String]

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.add-\(\.$topics)-to-\(\.$entityID)-at-\(\.$destination)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$entityID, \.$destination, \.$topics)) { entityID, destination, topics in
            DisplayRepresentation(
				title: LocalizedStringResource("intent.prediction.add-\(topics, format: .list(type: .and))-to-\(entityID)-at-\(destination)", comment: "Add <topics> to <entityID> at <destination>"),
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
		
		outline.load()
	
		guard let rowContainer = outline.findRowContainer(entityID: entityID) else {
			await outline.unload()
			await suspend()
			throw ZavalaAppIntentError.rowContainerNotFound
		}

		
		let rows = topics.map { Row(outline: outline, topicMarkdown: $0) }
		
		rows.forEach({ $0.detectData() })
		
		switch destination {
		case .insideAtStart:
			outline.createRowsInsideAtStart(rows, afterRowContainer: rowContainer)
		case .insideAtEnd:
			outline.createRowsInsideAtEnd(rows, afterRowContainer: rowContainer)
		case .outside:
			if let afterRow = rowContainer as? Row {
				outline.createRowsOutside(rows, afterRow: afterRow)
			} else {
				try await suspendUnloadAndThrow(outline: outline)
			}
		case .directlyBefore:
			if let beforeRow = rowContainer as? Row {
				outline.createRows(rows, beforeRow: beforeRow, moveCursor: false)
			} else {
				try await suspendUnloadAndThrow(outline: outline)
			}
		case .directlyAfter:
			if let afterRow = rowContainer as? Row {
				outline.createRowsDirectlyAfter(rows, afterRow: afterRow)
			} else {
				try await suspendUnloadAndThrow(outline: outline)
			}
		}
		
		await outline.unload()
		await suspend()
		return .result(value: rows.map({RowAppEntity(row: $0)}))
    }
	
	private func suspendUnloadAndThrow(outline: Outline) async throws {
		await outline.unload()
		await suspend()
		throw ZavalaAppIntentError.invalidDestinationForOutline
	}
	
}

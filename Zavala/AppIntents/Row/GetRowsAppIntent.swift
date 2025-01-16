//
//  GetRows.swift
//  Zavala
//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents
import VinOutlineKit

struct GetRowsAppIntent: AppIntent, CustomIntentMigratedAppIntent, PredictableIntent, ZavalaAppIntent {
    static let intentClassName = "GetRowsIntent"
    static let title: LocalizedStringResource = LocalizedStringResource("intent.title.get-rows", comment: "Get Rows")
    static let description = IntentDescription(LocalizedStringResource("intent.descrption.get-rows-outlines", comment: "Get Rows from an Outline."))

    @Parameter(title: LocalizedStringResource("intent.parameter.entity-id", comment: "Entity ID"))
	var entityID: EntityID

    @Parameter(title: LocalizedStringResource("intent.parameter.search", comment: "Search"))
    var search: String?

    @Parameter(title: LocalizedStringResource("intent.parameter.regular-expression", comment: "Regular Expression"), default: true)
    var regularExpression: Bool?

    @Parameter(title: LocalizedStringResource("intent.parameter.start-depth", comment: "Start Depth"), default: 1)
    var startDepth: Int?

    @Parameter(title: LocalizedStringResource("intent.parameter.end-depth", comment: "End Depth"), default: 200)
    var endDepth: Int?

    @Parameter(title: LocalizedStringResource("intent.parameter.completion-state", comment: "Completion State"))
    var completionState: RowCompletionStateAppEnum?

    @Parameter(title: LocalizedStringResource("intent.parameter.expanded-state", comment: "Expanded State"))
    var expandedState: RowExpandedStateAppEnum?

    @Parameter(title: LocalizedStringResource("intent.parameter.excluded-rows", comment: "Excluded Rows"))
	var excludedRows: [EntityID]?

    static var parameterSummary: some ParameterSummary {
        Summary("intent.summary.get-rows-matching-\(\.$search)-starting-at-\(\.$entityID)") {
            \.$regularExpression
            \.$completionState
            \.$expandedState
            \.$excludedRows
            \.$startDepth
            \.$endDepth
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$entityID, \.$search, \.$regularExpression, \.$completionState, \.$expandedState, \.$excludedRows, \.$startDepth, \.$endDepth)) { entityID, search, regularExpression, completionState, expandedState, excludedRows, startDepth, endDepth in
            DisplayRepresentation(
                title: LocalizedStringResource("intent.prediction.get-rows-matching-\(search!)-starting-at-\(entityID)", comment: "Get Rows matching <search> starting at <entityID>"),
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

		let visitor = GetRowsVisitor(searchText: search,
									 regularExpression: regularExpression ?? true,
									 startDepth: startDepth ?? 0,
									 endDepth: endDepth ?? 200,
									 completionState: completionState,
									 expandedState: expandedState,
									 excludedRowIDs: excludedRows)
		
		rowContainer.rows.forEach { $0.visit(visitor: visitor.visitor(_:)) }

		await outline.unload()
		await suspend()
		return .result(value: visitor.results.map({RowAppEntity(row: $0)}))
    }
}

@MainActor
private class GetRowsVisitor {
	
	var searchText: String? = nil
	var searchRegEx: NSRegularExpression? = nil
	let isTextSearch: Bool
	let regularExpression: Bool
	let startDepth: Int
	let endDepth: Int
	let completionState: RowCompletionStateAppEnum?
	let expandedState: RowExpandedStateAppEnum?
	let excludedRowIDs: [EntityID]?
	var results = [Row]()
	var level = 0
	
	init(searchText: String?, regularExpression: Bool, startDepth: Int, endDepth: Int, completionState: RowCompletionStateAppEnum?, expandedState: RowExpandedStateAppEnum?, excludedRowIDs: [EntityID]?) {
		if regularExpression {
			self.searchRegEx = searchText?.searchRegEx()
		} else {
			self.searchText = searchText
		}
		self.regularExpression = regularExpression
		self.startDepth = startDepth
		self.endDepth = endDepth
		self.isTextSearch = self.searchText != nil || self.searchRegEx != nil
		self.completionState = completionState
		self.expandedState = expandedState
		self.excludedRowIDs = excludedRowIDs
	}
	
	func visitor(_ visited: Row) {
		
		guard !(excludedRowIDs?.contains(visited.entityID) ?? false) else {
			return
		}
		
		var textPassed = false
		if isTextSearch {
			textPassed = matchedText(visited.topic)
			if !textPassed {
				textPassed = matchedText(visited.note)
			}
		} else {
			// Match against empty rows on an exact match without a valid search
			if regularExpression {
				textPassed = true
			} else {
				if (visited.topic?.string.isEmpty ?? true) || visited.note?.string.isEmpty ?? true {
					textPassed = true
				} else {
					textPassed = false
				}
			}
		}

		level = level + 1
		let depthPassed = startDepth <= level && endDepth >= level
		let completionPassed = passedCompletion(visited.isComplete ?? false)
		let expandedPassed = passedExpanded(visited.isExpanded)
		
		if textPassed && depthPassed && completionPassed && expandedPassed {
			results.append(visited)
		}
		
		visited.rows.forEach { row in
			row.visit(visitor: visitor)
		}
		
		level = level - 1
	}

	func matchedText(_ attrString: NSAttributedString?) -> Bool {
		var textMatched = true
		
		if let text = attrString?.string {
			if let searchText {
				if searchText != text {
					textMatched = false
				}
					
			}
			if let searchRegEx {
				if !searchRegEx.anyMatch(in: text.makeSearchable()) {
					textMatched = false
				}
			}
		} else {
			textMatched = false
		}
		
		return textMatched
	}
	
	func passedCompletion(_ complete: Bool) -> Bool {
		switch completionState {
		case .complete:
			return complete
		case .uncomplete:
			return !complete
		default:
			return true
		}
	}

	func passedExpanded(_ expanded: Bool) -> Bool {
		switch expandedState {
		case .expanded:
			return expanded
		case .collapsed:
			return !expanded
		default:
			return true
		}
	}

}



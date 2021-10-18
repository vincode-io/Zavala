//
//  GetRowsIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/13/21.
//

import Intents
import Templeton

class GetRowsIntentHandler: NSObject, ZavalaIntentHandler, GetRowsIntentHandling {

	func handle(intent: GetRowsIntent, completion: @escaping (GetRowsIntentResponse) -> Void) {
		resume()
		
		guard let entityID = intent.outlineOrRow?.toEntityID(), let outline = AccountManager.shared.findDocument(entityID)?.outline else {
			suspend()
			completion(.init(code: .success, userActivity: nil))
			return
		}
		
		outline.load()
		
		guard let rowContainer = outline.findRowContainer(entityID: entityID) else {
			outline.unload()
			suspend()
			completion(.init(code: .success, userActivity: nil))
			return
		}
		
		let regularExpression = intent.regularExpression == 1
		let excludedRowIDs = intent.excludedRows?.compactMap { $0.toEntityID() }
		
		let visitor = GetRowsVisitor(searchText: intent.search,
									 regularExpression: regularExpression,
									 startDepth: intent.startDepth?.intValue ?? 0,
									 endDepth: intent.endDepth?.intValue ?? 200,
									 completionState: intent.completionState,
									 expandedState: intent.expandedState,
									 excludedRowIDs: excludedRowIDs)
		
		rowContainer.rows.forEach { $0.visit(visitor: visitor.visitor(_:)) }
		
		outline.unload()
		suspend()
		let response = GetRowsIntentResponse(code: .success, userActivity: nil)
		response.rows = visitor.results.map { IntentEntityID(entityID: $0.entityID, display: $0.topic?.string) }
		completion(response)
	}
	
}

class GetRowsVisitor {
	
	var searchText: String? = nil
	var searchRegEx: NSRegularExpression? = nil
	let isTextSearch: Bool
	let regularExpression: Bool
	let startDepth: Int
	let endDepth: Int
	let completionState: IntentRowCompletionState
	let expandedState: IntentRowExpandedState
	let excludedRowIDs: [EntityID]?
	var results = [Row]()
	
	init(searchText: String?, regularExpression: Bool, startDepth: Int, endDepth: Int, completionState: IntentRowCompletionState, expandedState: IntentRowExpandedState, excludedRowIDs: [EntityID]?) {
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

		let level = visited.level + 1
		let depthPassed = startDepth <= level && endDepth >= level
		let completionPassed = passedCompletion(visited.isComplete)
		let expandedPassed = passedExpanded(visited.isExpanded)
		
		if textPassed && depthPassed && completionPassed && expandedPassed {
			results.append(visited)
		}
		
		visited.rows.forEach { row in
			row.visit(visitor: visitor)
		}
	}

	func matchedText(_ attrString: NSAttributedString?) -> Bool {
		var textMatched = true
		
		if let text = attrString?.string {
			if let searchText = searchText {
				if searchText != text {
					textMatched = false
				}
					
			}
			if let searchRegEx = searchRegEx {
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

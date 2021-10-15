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
		
		guard let entityID = intent.outlineOrRow?.toEntityID(), let rowContainer = AccountManager.shared.findRowContainer(entityID) else {
			suspend()
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		let isExactMatch = intent.exactSearchMatch == 1
		let visitor = GetRowsVisitor(searchText: intent.search,
									 isExactMatch: isExactMatch,
									 completionState: intent.completionState,
									 expandedState: intent.expandedState)
		
		rowContainer.rows.forEach { $0.visit(visitor: visitor.visitor(_:)) }
		
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
	let isExactMatch: Bool
	let completionState: IntentRowCompletionState
	let expandedState: IntentRowExpandedState
	var results = [Row]()
	
	init(searchText: String?, isExactMatch: Bool, completionState: IntentRowCompletionState, expandedState: IntentRowExpandedState) {
		if isExactMatch {
			self.searchText = searchText
		} else {
			self.searchRegEx = searchText?.searchRegEx()
		}
		self.isExactMatch = isExactMatch
		self.isTextSearch = self.searchText != nil || self.searchRegEx != nil
		self.completionState = completionState
		self.expandedState = expandedState
	}
	
	func visitor(_ visited: Row) {
		
		var textPassed = false
		if isTextSearch {
			textPassed = matchedText(visited.topic)
			if !textPassed {
				textPassed = matchedText(visited.note)
			}
		} else {
			// Match against empty rows on an exact match without a valid search
			if isExactMatch {
				if (visited.topic?.string.isEmpty ?? true) || visited.note?.string.isEmpty ?? true {
					textPassed = true
				} else {
					textPassed = false
				}
			} else {
				textPassed = true
			}
		}

		let completionPassed = passedCompletion(visited.isComplete)
		let expandedPassed = passedExpanded(visited.isExpanded)
		
		if textPassed && completionPassed && expandedPassed {
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

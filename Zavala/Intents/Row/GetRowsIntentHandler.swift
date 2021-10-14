//
//  GetRowsIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/13/21.
//

import Foundation

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
		let visitor = GetRowsVisitor(searchText: intent.search, isExactMatch: isExactMatch, completionState: intent.completionState)
		
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
	let completionState: IntentRowCompletionState
	var results = [Row]()
	
	init(searchText: String?, isExactMatch: Bool, completionState: IntentRowCompletionState) {
		if isExactMatch {
			self.searchText = searchText
		} else {
			self.searchRegEx = searchText?.searchRegEx()
		}
		isTextSearch = self.searchText != nil || self.searchRegEx != nil
		self.completionState = completionState
	}
	
	func visitor(_ visited: Row) {
		
		var textMatched = matchedText(visited.topic)
		if !textMatched {
			textMatched = matchedText(visited.note)
		}
		
		switch (true, true)  {
		case (textMatched, completionState == .unknown):
			results.append(visited)
		case (textMatched, completionState == .complete):
			if visited.isComplete {
				results.append(visited)
			}
		case (textMatched, completionState == .uncomplete):
			if !visited.isComplete {
				results.append(visited)
			}
		case (!isTextSearch, completionState == .complete):
			if visited.isComplete {
				results.append(visited)
			}
		case (!isTextSearch, completionState == .uncomplete):
			if !visited.isComplete {
				results.append(visited)
			}
		default:
			break
		}
		
		visited.rows.forEach { row in
			row.visit(visitor: visitor)
		}
	}

	func matchedText(_ attrString: NSAttributedString?) -> Bool {
		var textMatched = true
		
		if isTextSearch, let text = attrString?.string {
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
	
	func matchedCompletion(_ complete: Bool) -> Bool {
		switch completionState {
		case .complete:
			return complete
		case .uncomplete:
			return !complete
		default:
			return false
		}
	}
}

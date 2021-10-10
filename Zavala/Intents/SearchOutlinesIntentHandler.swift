//
//  SearchOutlinesIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import Templeton

class SearchOutlinesIntentHandler: NSObject, ZavalaIntentHandler, SearchOutlinesIntentHandling {
	
	private var search: Search?
	
	func resolveSearch(for intent: SearchOutlinesIntent, with completion: @escaping (SearchOutlinesSearchResolutionResult) -> Void) {
		guard let search = intent.search, !search.isEmpty else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: search))
	}
	
	func handle(intent: SearchOutlinesIntent, completion: @escaping (SearchOutlinesIntentResponse) -> Void) {
		guard let searchText = intent.search else {
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		resume()
		
		search = Search(searchText: searchText)
		
		search!.sortedDocuments { result in
			self.suspend()
			
			switch result {
			case .success(let documents):
				let response = SearchOutlinesIntentResponse(code: .success, userActivity: nil)
				response.outlines = documents.compactMap({ $0.outline }).map({ IntentOutline(outline: $0) })
				completion(response)
			case .failure:
				completion(.init(code: .failure, userActivity: nil))
			}
		}
	}

}

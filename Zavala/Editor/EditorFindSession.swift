//
//  EditorFindSession.swift
//  Zavala
//
//  Created by Maurice Parker on 1/17/24.
//

import UIKit
import VinOutlineKit

protocol EditorFindSessionDelegate {
	var outline: Outline? { get }
}

class EditorFindSession: UIFindSession {
	
	private var delegate: EditorFindSessionDelegate

	init(delegate: EditorFindSessionDelegate) {
		self.delegate = delegate
	}
	
	override var supportsReplacement: Bool {
		return true
	}
	
	override var resultCount: Int {
		guard let outline = delegate.outline else { return 0 }
		return outline.searchResultCount
	}
	
	override var highlightedResultIndex: Int {
		guard let outline = delegate.outline else { return 0 }
		return outline.currentSearchResult
	}
	
	override func performSearch(query: String, options: UITextSearchOptions?) {
		guard let outline = delegate.outline else { return }
		outline.search(for: query)
	}
	
	override func highlightNextResult(in direction: UITextStorageDirection) {
		guard let outline = delegate.outline else { return }

		switch direction {
		case .forward:
			outline.nextSearchResult()
		case .backward:
			outline.previousSearchResult()
		@unknown default:
			fatalError()
		}
	}
	
	override func invalidateFoundResults() {
		guard let outline = delegate.outline else { return }
		outline.search(for: "")
	}
	
}

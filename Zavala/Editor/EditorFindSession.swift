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
	func replaceCurrentSearchResult(with replacementText: String)
	func replaceAllSearchResults(with replacementText: String)
}

class EditorFindSession: UIFindSession {
	
	private var delegate: EditorFindSessionDelegate

	init(delegate: EditorFindSessionDelegate) {
		self.delegate = delegate
	}
	
	override var resultCount: Int {
		guard let outline = delegate.outline else { return 0 }
		return outline.searchResultCount
	}
	
	override var highlightedResultIndex: Int {
		guard let outline = delegate.outline else { return 0 }
		return outline.currentSearchResult
	}
	
	override var supportsReplacement: Bool {
		return true
	}
	
	override var allowsReplacementForCurrentlyHighlightedResult: Bool {
		guard let outline = delegate.outline else { return false }
		return outline.isCurrentSearchResultReplacable
	}
	
	override var searchResultDisplayStyle: UIFindSession.SearchResultDisplayStyle {
		set {}
		get { .none } // The other two options simply don't work right now...
	}
	
	override func performSearch(query: String, options: UITextSearchOptions?) {
		var outlineSearchOptions = Outline.SearchOptions()
		
		if options?.stringCompareOptions.contains(.caseInsensitive) ?? false {
			outlineSearchOptions.formUnion(.caseInsensitive)
		}
		
		if options?.wordMatchMethod == .fullWord {
			outlineSearchOptions.formUnion(.wholeWords)
		}
		
		guard let outline = delegate.outline else { return }
		outline.search(for: query, options: outlineSearchOptions)
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
	
	override func performSingleReplacement(query searchQuery: String, replacementString: String, options: UITextSearchOptions?) {
		delegate.replaceCurrentSearchResult(with: replacementString)
	}
	
	override func replaceAll(searchQuery: String, replacementString: String, options: UITextSearchOptions?) {
		delegate.replaceAllSearchResults(with: replacementString)
	}
	
	override func invalidateFoundResults() {
		guard let outline = delegate.outline else { return }
		outline.search(for: "", options: [])
	}
	
}

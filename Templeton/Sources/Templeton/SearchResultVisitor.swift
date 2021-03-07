//
//  SearchResultVisitor.swift
//  
//
//  Created by Maurice Parker on 3/7/21.
//

import Foundation

class SearchResultVisitor {
	
	let searchRegEx: NSRegularExpression?
	let isFiltered: Bool
	let isNotesHidden: Bool
	var searchResultCoordinates = [SearchResultCoordinates]()
	
	init(searchText: String, isFiltered: Bool, isNotesHidden: Bool) {
		let foldedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current)
		searchRegEx = try? NSRegularExpression(pattern: foldedText, options: .caseInsensitive)
		self.isFiltered = isFiltered
		self.isNotesHidden = isNotesHidden
	}
	
	func visitor(_ visited: Row) {
		guard !(isFiltered && visited.isComplete), let textRow = visited.textRow, let searchRegEx = searchRegEx else {
			return
		}
		
		var firstMatch = true
		
		if let topicText = textRow.topicPlainText?.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current) {
			for match in searchRegEx.matches(in: topicText, options: [], range: NSRange(location: 0, length: topicText.utf16.count)) as [NSTextCheckingResult] {
				let coordinates = SearchResultCoordinates(isCurrentResult: firstMatch, row: visited, isInNotes: false, range: match.range)
				searchResultCoordinates.append(coordinates)
				
				textRow.isPartOfSearchResult = true
				textRow.searchResultCoordinates.add(coordinates)
				
				firstMatch = false
			}
		}
		
		if !isNotesHidden, let noteText = textRow.notePlainText?.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current) {
			for match in searchRegEx.matches(in: noteText, options: [], range: NSRange(location: 0, length: noteText.utf16.count)) as [NSTextCheckingResult] {
				let coordinates = SearchResultCoordinates(isCurrentResult: firstMatch, row: visited, isInNotes: true, range: match.range)
				searchResultCoordinates.append(coordinates)

				textRow.isPartOfSearchResult = true
				textRow.searchResultCoordinates.add(coordinates)
				
				firstMatch = false
			}
		}
		
		visited.rows.forEach { row in
			row.visit(visitor: visitor)
		}
	}
	
}

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
	var firstMatch = true
	
	init(searchText: String, isFiltered: Bool, isNotesHidden: Bool) {
		searchRegEx = searchText.searchRegEx()
		self.isFiltered = isFiltered
		self.isNotesHidden = isNotesHidden
	}
	
	func visitor(_ visited: Row) {
		guard !(isFiltered && visited.isComplete), let searchRegEx = searchRegEx else {
			return
		}
		
		if let topicText = visited.topic?.string.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current) {
			for match in searchRegEx.matches(in: topicText, options: [], range: NSRange(location: 0, length: topicText.utf16.count)) as [NSTextCheckingResult] {
				let coordinates = SearchResultCoordinates(isCurrentResult: firstMatch, row: visited, isInNotes: false, range: match.range)
				searchResultCoordinates.append(coordinates)
				
				visited.isPartOfSearchResult = true
				visited.searchResultCoordinates.add(coordinates)
				
				firstMatch = false
			}
		}
		
		if !isNotesHidden, let noteText = visited.note?.string.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current) {
			for match in searchRegEx.matches(in: noteText, options: [], range: NSRange(location: 0, length: noteText.utf16.count)) as [NSTextCheckingResult] {
				let coordinates = SearchResultCoordinates(isCurrentResult: firstMatch, row: visited, isInNotes: true, range: match.range)
				searchResultCoordinates.append(coordinates)

				visited.isPartOfSearchResult = true
				visited.searchResultCoordinates.add(coordinates)
				
				firstMatch = false
			}
		}
		
		visited.rows.forEach { row in
			row.visit(visitor: visitor)
		}
	}
	
}

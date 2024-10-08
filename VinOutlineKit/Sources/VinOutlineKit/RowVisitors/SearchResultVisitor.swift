//
//  SearchResultVisitor.swift
//  
//
//  Created by Maurice Parker on 3/7/21.
//

import Foundation

@MainActor
final class SearchResultVisitor {
	
	let searchRegEx: NSRegularExpression?
	let isCompletedFilterOn: Bool
	let isNotesFilterOn: Bool
	var searchResultCoordinates = [SearchResultCoordinates]()
	var firstMatch = true
	
	init(searchText: String, options: Outline.SearchOptions, isCompletedFilterOn: Bool, isNotesFilterOn: Bool) {
		let search = options.contains(.wholeWords) ? "\\b\(searchText)\\b" : searchText
		
		if options.contains(.caseInsensitive) {
			searchRegEx = search.searchRegEx(caseInsensitive: true)
		} else {
			searchRegEx = search.searchRegEx(caseInsensitive: false)
		}
		
		self.isCompletedFilterOn = isCompletedFilterOn
		self.isNotesFilterOn = isNotesFilterOn
	}
	
	func visitor(_ visited: Row) {
		guard !(isCompletedFilterOn && visited.isComplete ?? false), let searchRegEx else {
			return
		}
		
		if let topicText = visited.topic?.string.makeSearchable() {
			for match in searchRegEx.allMatches(in: topicText) {
				let coordinates = SearchResultCoordinates(isCurrentResult: firstMatch, row: visited, isInNotes: false, range: match.range)
				searchResultCoordinates.append(coordinates)
				
				visited.isPartOfSearchResult = true
				visited.searchResultCoordinates.add(coordinates)
				
				firstMatch = false
			}
		}
		
		if !isNotesFilterOn, let noteText = visited.note?.string.makeSearchable() {
			for match in searchRegEx.allMatches(in: noteText) {
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

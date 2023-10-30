//
//  SearchResultCoordinates.swift
//  
//
//  Created by Maurice Parker on 3/6/21.
//

import Foundation

public class SearchResultCoordinates: Equatable, Hashable {

	public var isCurrentResult: Bool
	public var row: Row
	public var isInNotes: Bool
	public var range: NSRange
		
	init(isCurrentResult: Bool, row: Row, isInNotes: Bool, range: NSRange) {
		self.isCurrentResult = isCurrentResult
		self.row = row
		self.isInNotes = isInNotes
		self.range = range
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(isCurrentResult)
		hasher.combine(row)
		hasher.combine(isInNotes)
		hasher.combine(range)
	}

	public static func == (lhs: SearchResultCoordinates, rhs: SearchResultCoordinates) -> Bool {
		return lhs.isCurrentResult == rhs.isCurrentResult && lhs.row == rhs.row && lhs.isInNotes && rhs.isInNotes && lhs.range == rhs.range
	}
	
}

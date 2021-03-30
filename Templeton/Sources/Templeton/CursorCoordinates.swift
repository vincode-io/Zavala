//
//  File.swift
//  
//
//  Created by Maurice Parker on 12/20/20.
//

import UIKit

public protocol CursorCoordinatesProvider {
	var coordinates: CursorCoordinates? { get }
}

public struct CursorCoordinates {

	public var row: Row
	public var isInNotes: Bool
	public var selection: NSRange
	
	public init(row: Row, isInNotes: Bool, selection: NSRange) {
		self.row = row
		self.isInNotes = isInNotes
		self.selection = selection
	}

	public static var lastKnownCoordinates: CursorCoordinates?

	public static var currentCoordinates: CursorCoordinates? {
		if let provider = UIResponder.currentFirstResponder as? CursorCoordinatesProvider {
			return provider.coordinates
		}
		return nil
	}

	public static var bestCoordinates: CursorCoordinates? {
		if let current = currentCoordinates {
			return current
		}
		return lastKnownCoordinates
	}
	
}

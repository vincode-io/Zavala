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
	public var cursorPosition: Int
	
	public init(row: Row, isInNotes: Bool, cursorPosition: Int) {
		self.row = row
		self.isInNotes = isInNotes
		self.cursorPosition = cursorPosition
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

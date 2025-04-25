//
//  CursorCoordinatesProvider.swift
//  
//
//  Created by Maurice Parker on 12/20/20.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

@MainActor
public protocol CursorCoordinatesProvider {
	var coordinates: CursorCoordinates? { get }
}

@MainActor
public struct CursorCoordinates {

	public var rowID: String
	public var isInNotes: Bool
	public var selection: NSRange
	
	public init(rowID: String, isInNotes: Bool, selection: NSRange) {
		self.rowID = rowID
		self.isInNotes = isInNotes
		self.selection = selection
	}

	public private(set) static var lastKnownCoordinates: CursorCoordinates?

	@available(iOSApplicationExtension, unavailable)
	public static var currentCoordinates: CursorCoordinates? {
		#if canImport(UIKit)
		if let provider = UIResponder.currentFirstResponder as? CursorCoordinatesProvider {
			return provider.coordinates
		}
		#endif
		return nil
	}

	@available(iOSApplicationExtension, unavailable)
	public static var bestCoordinates: CursorCoordinates? {
		if let current = currentCoordinates {
			return current
		}
		return lastKnownCoordinates
	}
	
	@available(iOSApplicationExtension, unavailable)
	public static func clearLastKnownCoordinates() {
		lastKnownCoordinates = nil
	}
	
	@available(iOSApplicationExtension, unavailable)
	public static func updateLastKnownCoordinates() {
		if let coordinates = currentCoordinates {
			lastKnownCoordinates = coordinates
		}
	}
	
}

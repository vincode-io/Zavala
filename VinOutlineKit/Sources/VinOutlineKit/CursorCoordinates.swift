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

	public let rowID: String
	public let isInNotes: Bool
	public let selection: NSRange

	public init(rowID: String, isInNotes: Bool, selection: NSRange) {
		self.rowID = rowID
		self.isInNotes = isInNotes
		self.selection = selection
	}

	@available(iOSApplicationExtension, unavailable)
	public static var currentCoordinates: CursorCoordinates? {
		#if canImport(UIKit)
		if let provider = UIResponder.currentFirstResponder as? CursorCoordinatesProvider {
			return provider.coordinates
		}
		#endif
		return nil
	}

}

//
//  OutlineCommand.swift
//
//  Created by Maurice Parker on 11/27/20.
//

import Foundation
import RSCore

public protocol OutlineCommandDelegate: AnyObject {
	var currentCoordinates: CursorCoordinates? { get }
	func restoreCursorPosition(_: CursorCoordinates)
}

public protocol OutlineCommand: UndoableCommand {
	var delegate: OutlineCommandDelegate? { get }
	var outline: Outline { get }
	var cursorCoordinates: CursorCoordinates? { get set }
}

public extension OutlineCommand {
	
	func saveCursorCoordinates() {
		let coordinates = delegate?.currentCoordinates
		cursorCoordinates = coordinates
		outline.cursorCoordinates = coordinates
	}
	
	func restoreCursorPosition() {
		if let cursorCoordinates = cursorCoordinates {
			delegate?.restoreCursorPosition(cursorCoordinates)
		}
	}
	
}

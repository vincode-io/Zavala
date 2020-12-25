//
//  OutlineCommand.swift
//
//  Created by Maurice Parker on 11/27/20.
//

import Foundation
import RSCore

public protocol OutlineCommandDelegate: class {
	func applyChanges(_: ShadowTableChanges)
	func applyChangesRestoringCursor(_: ShadowTableChanges)
	func restoreCursorPosition(_: CursorCoordinates)
}

public protocol OutlineCommand: UndoableCommand {
	var delegate: OutlineCommandDelegate? { get }
	var cursorCoordinates: CursorCoordinates? { get set }
}

public extension OutlineCommand {
	
	func saveCursorCoordinates() {
		cursorCoordinates = CursorCoordinates.currentCoordinates
	}
	
	func restoreCursorPosition() {
		if let cursorCoordinates = cursorCoordinates {
			delegate?.restoreCursorPosition(cursorCoordinates)
		}
	}
	
}

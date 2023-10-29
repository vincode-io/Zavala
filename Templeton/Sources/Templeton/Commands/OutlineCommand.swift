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

public class OutlineCommand: UndoableCommand {
	
	var actionName: String
	public var undoActionName: String {
		return actionName
	}
	public var redoActionName: String {
		return actionName
	}
	
	public var undoManager: UndoManager
	weak public var delegate: OutlineCommandDelegate?
	public var cursorCoordinates: CursorCoordinates?
	public var outline: Outline

	init(actionName: String,
		 undoManager: UndoManager,
		 delegate: OutlineCommandDelegate? = nil,
		 outline: Outline,
		 cursorCoordinates: CursorCoordinates? = nil) {
		self.actionName = actionName
		self.undoManager = undoManager
		self.delegate = delegate
		self.outline = outline
		self.cursorCoordinates = cursorCoordinates
	}
	
	public func perform() {
		fatalError("Undo function not implemented.")
	}
	
	public func undo() {
		fatalError("Undo function not implemented.")
	}
}

extension OutlineCommand {
	
	func saveCursorCoordinates() {
		let coordinates = delegate?.currentCoordinates
		cursorCoordinates = coordinates
		outline.cursorCoordinates = coordinates
	}
	
	func restoreCursorPosition() {
		if let cursorCoordinates {
			delegate?.restoreCursorPosition(cursorCoordinates)
		}
	}
	
}

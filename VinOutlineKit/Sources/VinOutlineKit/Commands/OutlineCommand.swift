//
//  OutlineCommand.swift
//
//  Created by Maurice Parker on 11/27/20.
//

import Foundation
import VinUtility

@MainActor
public protocol OutlineCommandDelegate: AnyObject {
	var currentCoordinates: CursorCoordinates? { get }
	func restoreCursorPosition(_: CursorCoordinates)
}

@MainActor
public class OutlineCommand {
	
	var actionName: String
	
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
	
	public func execute() {
		registerUndo()
		saveCursorCoordinates()
		perform()
	}
	
	func unexecute() {
		registerRedo()
		undo()
		restoreCursorPosition()
	}
	
	func perform() {
		fatalError("Perform function not implemented.")
	}
	
	func undo() {
		fatalError("Undo function not implemented.")
	}
	
	func registerUndo() {
		undoManager.setActionName(actionName)
		undoManager.registerUndo(withTarget: self) { _ in
			MainActor.assumeIsolated {
				self.unexecute()
			}
		}
	}

	func registerRedo() {
		undoManager.setActionName(actionName)
		undoManager.registerUndo(withTarget: self) { _ in
			MainActor.assumeIsolated {
				self.execute()
			}
		}
	}
	
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

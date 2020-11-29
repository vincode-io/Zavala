//
//  StackedUndoManager.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/29/20.
//

import Foundation

class StackedUndoManger: UndoManager {
	
	let mainUndoManager: UndoManager
	let fallBackUndoManager: UndoManager

	init(mainUndoManager: UndoManager, fallBackUndoManager: UndoManager) {
		self.mainUndoManager = mainUndoManager
		self.fallBackUndoManager = fallBackUndoManager
	}
	
	override func beginUndoGrouping() {
		mainUndoManager.beginUndoGrouping()
	}

	override func endUndoGrouping() {
		mainUndoManager.endUndoGrouping()
	}
	
	override var groupingLevel: Int {
		return mainUndoManager.groupingLevel
	}

	override func disableUndoRegistration() {
		mainUndoManager.disableUndoRegistration()
	}

	override func enableUndoRegistration() {
		mainUndoManager.enableUndoRegistration()
	}

	override var isUndoRegistrationEnabled: Bool {
		return mainUndoManager.isUndoRegistrationEnabled
	}

	override var groupsByEvent: Bool {
		get {
			return mainUndoManager.groupsByEvent
		}
		set {
			mainUndoManager.groupsByEvent = newValue
		}
	}

	override var levelsOfUndo: Int {
		get {
			return mainUndoManager.levelsOfUndo
		}
		set {
			mainUndoManager.levelsOfUndo = newValue
		}
	}

	override var runLoopModes: [RunLoop.Mode] {
		get {
			return mainUndoManager.runLoopModes
		}
		set {
			mainUndoManager.runLoopModes = newValue
		}
	}

	override func undo() {
		if mainUndoManager.canUndo {
			mainUndoManager.undo()
		} else {
			fallBackUndoManager.undo()
		}
	}
	
	override func redo() {
		if mainUndoManager.canRedo {
			mainUndoManager.redo()
		} else {
			fallBackUndoManager.redo()
		}
	}

	override func undoNestedGroup() {
		mainUndoManager.undoNestedGroup()
	}

	override var canUndo: Bool {
		return mainUndoManager.canUndo || fallBackUndoManager.canUndo
	}

	override var canRedo: Bool {
		return mainUndoManager.canRedo || fallBackUndoManager.canRedo
	}
	
	override var isUndoing: Bool {
		return mainUndoManager.isUndoing || fallBackUndoManager.isUndoing
	}

	override var isRedoing: Bool {
		return mainUndoManager.isRedoing || fallBackUndoManager.isRedoing
	}

	override func removeAllActions() {
		mainUndoManager.removeAllActions()
	}
	
	override func removeAllActions(withTarget target: Any) {
		mainUndoManager.removeAllActions(withTarget: target)
	}

	override func registerUndo(withTarget target: Any, selector: Selector, object anObject: Any?) {
		mainUndoManager.registerUndo(withTarget: target, selector: selector, object: anObject)
	}
	
	override func prepare(withInvocationTarget target: Any) -> Any {
		mainUndoManager.prepare(withInvocationTarget: target)
	}
	
	@available(iOS 5.0, macCatalyst 13.0, *)
	override func setActionIsDiscardable(_ discardable: Bool) {
		mainUndoManager.setActionIsDiscardable(discardable)
	}
	
	@available(iOS 5.0, macCatalyst 13.0, *)
	override var undoActionIsDiscardable: Bool {
		return mainUndoManager.undoActionIsDiscardable
	}

	@available(iOS 5.0, macCatalyst 13.0, *)
	override var redoActionIsDiscardable: Bool {
		return mainUndoManager.redoActionIsDiscardable
	}

	override var undoActionName: String {
		return mainUndoManager.undoActionName
	}

	override var redoActionName: String {
		return mainUndoManager.redoActionName
	}

	override func setActionName(_ actionName: String) {
		mainUndoManager.setActionName(actionName)
	}
	
	override var undoMenuItemTitle: String {
		return mainUndoManager.undoMenuItemTitle
	}

	override var redoMenuItemTitle: String {
		return mainUndoManager.redoMenuItemTitle
	}
	
	override func undoMenuTitle(forUndoActionName actionName: String) -> String {
		return mainUndoManager.undoMenuTitle(forUndoActionName: actionName)
	}

	override func redoMenuTitle(forUndoActionName actionName: String) -> String {
		return mainUndoManager.redoMenuTitle(forUndoActionName: actionName)
	}

}

//
//  EditorOutlineCommand.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/27/20.
//

import UIKit
import RSCore
import Templeton

protocol EditorOutlineCommandDelegate: class {
	func applyChanges(_: Outline.ShadowTableChanges)
	func applyChangesRestoringCursor(_: Outline.ShadowTableChanges)
}

protocol EditorOutlineCommand: UndoableCommand {
	var delegate: EditorOutlineCommandDelegate? { get }
}

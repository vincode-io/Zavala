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
	func applyChanges(_: ShadowTableChanges)
	func applyChangesRestoringCursor(_: ShadowTableChanges)
	func restoreCursorPosition(_: CursorCoordinates)
}

protocol EditorOutlineCommand: UndoableCommand {
	var delegate: EditorOutlineCommandDelegate? { get }
	var cursorCoordinates: CursorCoordinates? { get set }
}

extension EditorOutlineCommand {
	
	func saveCursorCoordinates() {
		if let textView = UIResponder.currentFirstResponder as? OutlineTextView, let headline = textView.headline {
			let isInNotes = textView is EditorHeadlineNoteTextView
			cursorCoordinates = CursorCoordinates(headline: headline, isInNotes: isInNotes, cursorPosition: textView.cursorPosition)
		}
	}
	
	func restoreCursorPosition() {
		if let cursorCoordinates = cursorCoordinates {
			delegate?.restoreCursorPosition(cursorCoordinates)
		}
	}
	
}

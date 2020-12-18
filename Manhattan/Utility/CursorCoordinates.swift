//
//  CursorCoordinates.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/16/20.
//

import UIKit
import Templeton

struct CursorCoordinates {

	var headline: Headline
	var isInNotes: Bool
	var cursorPosition: Int

	static var currentCoordinates: CursorCoordinates? {
		if let textView = UIResponder.currentFirstResponder as? OutlineTextView, let headline = textView.headline {
			let isInNotes = textView is EditorHeadlineNoteTextView
			return CursorCoordinates(headline: headline, isInNotes: isInNotes, cursorPosition: textView.cursorPosition)
		}
		return nil
	}
}

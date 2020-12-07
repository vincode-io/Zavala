//
//  EditorTitleTextView.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit

protocol EditorTitleTextViewDelegate: class {
	var undoManager: UndoManager? { get }
}

class EditorTitleTextView: OutlineTextView {
	
	weak var editorDelegate: EditorTitleTextViewDelegate?

	override var editorUndoManager: UndoManager? {
		return editorDelegate?.undoManager
	}

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


}

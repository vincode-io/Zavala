//
//  OutlineTextView.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton

class OutlineTextView: UITextView {
	
	var headline: Headline?

	var editorUndoManager: UndoManager? {
		fatalError("editorUndoManager has not been implemented")
	}
	
	override var undoManager: UndoManager? {
		guard let textViewUndoManager = super.undoManager, let controllerUndoManager = editorUndoManager else { return nil }
		if stackedUndoManager == nil {
			stackedUndoManager = StackedUndoManger(mainUndoManager: textViewUndoManager, fallBackUndoManager: controllerUndoManager)
		}
		return stackedUndoManager
	}
	
	var isSelecting: Bool {
		return !(selectedTextRange?.isEmpty ?? true)
	}
	
	var cursorPosition: Int {
		return selectedRange.location
	}
	
	var lastCursorPosition = 0
	
	var attributedTexts: HeadlineTexts? {
		fatalError("attibutedTexts has not been implemented")
	}

	private var stackedUndoManager: UndoManager?

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		textDropDelegate = self
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func resignFirstResponder() -> Bool {
		lastCursorPosition = cursorPosition
		return super.resignFirstResponder()
	}
	
}

extension OutlineTextView: UITextDropDelegate {
	
	// We dont' allow local text drops because regular dragging and dropping of Headlines was dropping Markdown into our text view
	func textDroppableView(_ textDroppableView: UIView & UITextDroppable, proposalForDrop drop: UITextDropRequest) -> UITextDropProposal {
		if drop.dropSession.localDragSession == nil {
			return UITextDropProposal(operation: .copy)
		} else {
			return UITextDropProposal(operation: .cancel)
		}
	}
	
}

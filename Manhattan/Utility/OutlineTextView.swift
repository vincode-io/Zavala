//
//  OutlineTextView.swift
//  Manhattan
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton

extension Selector {
	static let toggleBoldface = #selector(OutlineTextView.toggleBoldface(_:))
	static let toggleItalics = #selector(OutlineTextView.toggleItalics(_:))
	static let toggleUnderline = #selector(OutlineTextView.toggleUnderline(_:))
}

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
	private static let dropDelegate = OutlineTextDropDelegate()
	
	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)

		textDropDelegate = Self.dropDelegate

		// These gesture recognizers will conflict with context menu preview dragging if not removed.
		if traitCollection.userInterfaceIdiom != .mac {
			gestureRecognizers?.forEach {
				if $0.name == "dragInitiation"
					|| $0.name == "dragExclusionRelationships"
					|| $0.name == "dragFailureRelationships"
					|| $0.name == "com.apple.UIKit.longPressClickDriverPrimary" {
					removeGestureRecognizer($0)
				}
			}
		}

		self.isScrollEnabled = false
		self.textContainer.lineFragmentPadding = 0
		self.textContainerInset = .zero
		self.backgroundColor = .clear
		self.adjustsFontForContentSizeCategory = true
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		if traitCollection.userInterfaceIdiom != .mac {
			switch action {
			case .toggleBoldface, .toggleItalics, .toggleUnderline:
				return isSelecting
			default:
				return super.canPerformAction(action, withSender: sender)
			}
		} else {
			return super.canPerformAction(action, withSender: sender)
		}
	}
	
}

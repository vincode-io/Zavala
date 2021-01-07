//
//  OutlineTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton

extension Selector {
	static let toggleBoldface = #selector(OutlineTextView.outlineToggleBoldface(_:))
	static let toggleItalics = #selector(OutlineTextView.outlineToggleItalics(_:))
	static let editLink = #selector(OutlineTextView.editLink(_:))
}

class OutlineTextView: UITextView {
	
	var row: Row?

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
	
	var textRowStrings: TextRowStrings? {
		fatalError("attibutedTexts has not been implemented")
	}

	let toggleBoldCommand = UIKeyCommand(title: L10n.bold, action: .toggleBoldface, input: "b", modifierFlags: [.command])
	let toggleItalicsCommand = UIKeyCommand(title: L10n.italic, action: .toggleItalics, input: "i", modifierFlags: [.command])
	let editLinkCommand = UIKeyCommand(title: L10n.link, action: .editLink, input: "k", modifierFlags: [.command])

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
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func saveText() {
		fatalError("saveText has not been implemented")
	}
	
	func findAndSelectLink() -> (String?, NSRange) {
		var effectiveRange = NSRange()
		for i in selectedRange.lowerBound..<selectedRange.upperBound {
			if let link = textStorage.attribute(.link, at: i, effectiveRange: &effectiveRange) as? URL {
				return (link.absoluteString, effectiveRange)
			}
		}
		return (nil, selectedRange)
	}
	
	func updateLinkForCurrentSelection(link: String?, range: NSRange) {
		if let link = link, let url = URL(string: link) {
			textStorage.addAttribute(.link, value: url, range: range)
		} else {
			textStorage.removeAttribute(.link, range: range)
		}
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .toggleBoldface, .toggleItalics, .editLink:
			return isSelecting
		default:
			return super.canPerformAction(action, withSender: sender)
		}
	}
	
	@objc func outlineToggleBoldface(_ sender: Any?) {
		super.toggleBoldface(sender)
	}
	
	@objc func editLink(_ sender: Any?) {
		fatalError("editLink has not been implemented")
	}
	
	@objc func outlineToggleItalics(_ sender: Any?) {
		super.toggleItalics(sender)
	}
	
	override func buildMenu(with builder: UIMenuBuilder) {
		super.buildMenu(with: builder)
		
		if isSelecting {
			let formattingMenu = UIMenu(title: "", options: .displayInline, children: [toggleBoldCommand, toggleItalicsCommand])
			builder.insertSibling(formattingMenu, afterMenu: .standardEdit)
			
			let editMenu = UIMenu(title: "", options: .displayInline, children: [editLinkCommand])
			builder.insertSibling(editMenu, afterMenu: .standardEdit)
		}
	}
	
}

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
	
	var row: Row? {
		didSet {
			rowWasUpdated()
		}
	}

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
	
	var selectedText: String? {
		if let textRange = selectedTextRange {
			return text(in: textRange)
		}
		return nil
	}
	
	var cursorPosition: Int {
		return selectedRange.location
	}
	
	var isTextChanged = false
	
	var textRowStrings: TextRowStrings? {
		fatalError("attibutedTexts has not been implemented")
	}

	var cleansedAttributedText: NSAttributedString {
		let cleanText = NSMutableAttributedString(attributedString: attributedText)
		cleanText.enumerateAttribute(.backgroundColor, in:  NSRange(0..<cleanText.length)) { value, range, stop in
			cleanText.removeAttribute(.backgroundColor, range: range)
		}
		return cleanText
	}
	
	let toggleBoldCommand = UIKeyCommand(title: L10n.bold, action: .toggleBoldface, input: "b", modifierFlags: [.command])
	let toggleItalicsCommand = UIKeyCommand(title: L10n.italic, action: .toggleItalics, input: "i", modifierFlags: [.command])
	let editLinkCommand = UIKeyCommand(title: L10n.link, action: .editLink, input: "k", modifierFlags: [.command])

	private var stackedUndoManager: UndoManager?
	private static let dropDelegate = OutlineTextDropDelegate()

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		let textStorage = NSTextStorage()
		let layoutManager = OutlineLayoutManager()
		textStorage.addLayoutManager(layoutManager)
		let textContainer = NSTextContainer()
		layoutManager.addTextContainer(textContainer)
		
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
	
	func rowWasUpdated() {
	}
	
	func detectData() {
		guard let text = attributedText?.string, !text.isEmpty else { return }
		
		let detector = NSDataDetector(dataTypes: [.url])
		detector.enumerateMatches(in: text) { (range, match) in
			switch match {
			case .url(let url), .email(_, let url):
				var effectiveRange = NSRange()
				if let link = textStorage.attribute(.link, at: range.location, effectiveRange: &effectiveRange) as? URL {
					if range != effectiveRange || link != url {
						isTextChanged = true
						textStorage.removeAttribute(.link, range: effectiveRange)
						textStorage.addAttribute(.link, value: url, range: range)
					}
				} else {
					isTextChanged = true
					textStorage.addAttribute(.link, value: url, range: range)
				}
			default:
				break
			}
		}
	}
	
	func findAndSelectLink() -> (String?, String?, NSRange) {
		var effectiveRange = NSRange()
		for i in selectedRange.lowerBound..<selectedRange.upperBound {
			if let link = textStorage.attribute(.link, at: i, effectiveRange: &effectiveRange) as? URL {
				let text = textStorage.attributedSubstring(from: effectiveRange).string
				return (link.absoluteString, text, effectiveRange)
			}
		}
		let text = textStorage.attributedSubstring(from: selectedRange).string
		return (nil, text, selectedRange)
	}
	
	func updateLinkForCurrentSelection(text: String, link: String?, range: NSRange) {
		if text.isEmpty {
			textStorage.replaceCharacters(in: range, with: text)
		} else {
			textStorage.replaceCharacters(in: range, with: "\(text) ")
		}
		if let link = link, let url = URL(string: link) {
			let range = NSRange(location: range.location, length: text.count)
			textStorage.addAttribute(.link, value: url, range: range)
		} else {
			if range.length > 0 {
				textStorage.removeAttribute(.link, range: range)
			}
		}
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .editLink:
			return true
		case .toggleBoldface, .toggleItalics:
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

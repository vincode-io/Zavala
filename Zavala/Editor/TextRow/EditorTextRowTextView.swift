//
//  EditorTextRowTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton

extension Selector {
	static let toggleBoldface = #selector(EditorTextRowTextView.outlineToggleBoldface(_:))
	static let toggleItalics = #selector(EditorTextRowTextView.outlineToggleItalics(_:))
	static let editLink = #selector(EditorTextRowTextView.editLink(_:))
}

class EditorTextRowTextView: UITextView {
	
	var row: Row? {
		didSet {
			rowWasUpdated()
		}
	}

	var indentionLevel = 0 {
		didSet {
			indentionLevelWasUpdated()
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
	
	var isBoldToggledOn: Bool {
		if let symbolicTraits = (typingAttributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits {
			if symbolicTraits.contains(.traitBold) {
				return true
			}
		}
		return false
	}
	
	var isItalicToggledOn: Bool {
		if let symbolicTraits = (typingAttributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits {
			if symbolicTraits.contains(.traitItalic) {
				return true
			}
		}
		return false
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

	private var dropInteractionDelegate: EditorTextRowDropInteractionDelegate!
	private var stackedUndoManager: UndoManager?

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		let textStorage = NSTextStorage()
		let layoutManager = OutlineLayoutManager()
		textStorage.addLayoutManager(layoutManager)
		let textContainer = NSTextContainer()
		layoutManager.addTextContainer(textContainer)
		
		super.init(frame: frame, textContainer: textContainer)

		textStorage.delegate = self

		self.dropInteractionDelegate = EditorTextRowDropInteractionDelegate(textView: self)
		self.addInteraction(UIDropInteraction(delegate: dropInteractionDelegate))

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
	
	func indentionLevelWasUpdated() {
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
		if selectedRange.length == 0 && selectedRange.lowerBound < textStorage.length {
			if let link = textStorage.attribute(.link, at: selectedRange.lowerBound, effectiveRange: &effectiveRange) as? URL {
				let text = textStorage.attributedSubstring(from: effectiveRange).string
				return (link.absoluteString, text, effectiveRange)
			}
		} else {
			for i in selectedRange.lowerBound..<selectedRange.upperBound {
				if let link = textStorage.attribute(.link, at: i, effectiveRange: &effectiveRange) as? URL {
					let text = textStorage.attributedSubstring(from: effectiveRange).string
					return (link.absoluteString, text, effectiveRange)
				}
			}
		}
		let text = textStorage.attributedSubstring(from: selectedRange).string
		return (nil, text, selectedRange)
	}
	
	func updateLinkForCurrentSelection(text: String, link: String?, range: NSRange) {
		textStorage.replaceCharacters(in: range, with: text)
		selectedRange = NSRange(location: range.location + text.count, length: 0)
		
		let newRange = NSRange(location: range.location, length: text.count)

		if let link = link, let url = URL(string: link) {
			textStorage.addAttribute(.link, value: url, range: newRange)
		} else {
			if newRange.length > 0 {
				textStorage.removeAttribute(.link, range: newRange)
			}
		}
	}
	
	func replaceCharacters(_ range: NSRange, withText text: String) {
		textStorage.replaceCharacters(in: range, with: text)
		isTextChanged = true
		saveText()
	}
	
	func replaceCharacters(_ range: NSRange, withImage image: UIImage) {
		let attachment = EditorTextRowTextAttachment()
		attachment.image = image
		let imageAttrText = NSAttributedString(attachment: attachment)

		let savedTypingAttributes = typingAttributes
		textStorage.replaceCharacters(in: range, with: imageAttrText)
		selectedRange = .init(location: range.location + imageAttrText.length, length: 0)
		typingAttributes = savedTypingAttributes
		isTextChanged = true
		saveText()
		invalidateLayout()
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .toggleBoldface, .toggleItalics, .editLink:
			return true
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

	func didBecomeActive() {
		fatalError("didBecomeActive has not been implemented")
	}
	
	func invalidateLayout() {
		fatalError("invalidateLayout has not been implemented")
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

// MARK: NSTextStorageDelegate

extension EditorTextRowTextView: NSTextStorageDelegate {
	
	func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
		textStorage.enumerateAttributes(in: editedRange, options: .longestEffectiveRangeNotRequired) { (attributes, range, _) in
			var newAttributes = attributes
			
			for key in attributes.keys {
				if key == .attachment, let nsAttachment = attributes[key] as? NSTextAttachment {
					guard !(nsAttachment is EditorTextRowTextAttachment) else { continue }
					if let image = nsAttachment.image {
						let attachment = EditorTextRowTextAttachment(image: image)
						newAttributes[key] = attachment
					} else if let fileContents = nsAttachment.fileWrapper?.regularFileContents {
						let attachment = EditorTextRowTextAttachment(data: fileContents, ofType: nsAttachment.fileType)
						newAttributes[key] = attachment
					}
				}
			}

			textStorage.setAttributes(newAttributes, range: range)
		}
	}
	
}
//
//  EditorRowTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import AsyncAlgorithms
import VinOutlineKit
import VinUtility

extension Selector {
	static let editLink = #selector(EditorRowTextView.editLink(_:))
}

extension NSAttributedString.Key {
	static let selectedSearchResult: NSAttributedString.Key = .init("selectedSearchResult")
	static let searchResult: NSAttributedString.Key = .init("searchResult")
}

class EditorRowTextView: UITextView {
	
	var row: Row?
	var baseAttributes = [NSAttributedString.Key : Any]()
	var previousSelectedTextRange: UITextRange?

	var lineHeight: CGFloat {
		if let textRange = textRange(from: beginningOfDocument, to: beginningOfDocument) {
			return firstRect(for: textRange).height
		}
		return 0
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
	
	var rowStrings: RowStrings {
		fatalError("rowStrings has not been implemented")
	}

	var cleansedAttributedText: NSAttributedString {
		let cleanText = NSMutableAttributedString(attributedString: attributedText)
		cleanText.enumerateAttribute(.backgroundColor, in:  NSRange(0..<cleanText.length)) { value, range, stop in
			cleanText.removeAttribute(.backgroundColor, range: range)
		}
		return cleanText
	}
	
	var inactivityTask: Task<(), Never>?
	var activityChannel = AsyncChannel<Void>()
    var textViewHeight: CGFloat?

	private var dropInteractionDelegate: EditorRowDropInteractionDelegate!
	private var stackedUndoManager: UndoManager?

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		let textContentStorage = NSTextContentStorage()
		let textLayoutManager = NSTextLayoutManager()
		textContentStorage.addTextLayoutManager(textLayoutManager)
		let textContainer = NSTextContainer()
		textLayoutManager.textContainer = textContainer
		
		super.init(frame: frame, textContainer: textContainer)
		
		textLayoutManager.delegate = self
		textDropDelegate = self
		
		self.dropInteractionDelegate = EditorRowDropInteractionDelegate(textView: self)
		self.addInteraction(UIDropInteraction(delegate: dropInteractionDelegate))
		
		// These gesture recognizers will conflict with the row dragging if not removed.
		if traitCollection.userInterfaceIdiom != .mac {
			gestureRecognizers?.forEach {
				if $0.name == "com.apple.UIKit.dragInitiation" ||
					$0.name == "com.apple.UIKit.dragFailureRelationships" ||
					$0.name == "com.apple.UIKit.dragExclusionRelationships" ||
					$0.name == "com.apple.UIKit.longPressClickDriverPrimary" ||
					$0.name == "com.apple.UIKit.clickPresentationExclusion" ||
					$0.name == "com.apple.UIKit.clickPresentationFailure" {
					removeGestureRecognizer($0)
				}
			}
		}
			
		self.allowsEditingTextAttributes = true
		self.isScrollEnabled = false
		self.textContainer.lineFragmentPadding = 0
		self.textContainerInset = .zero
		self.backgroundColor = .clear		
		self.focusGroupIdentifier = EditorViewController.focusGroupIdentifier

		if #available(iOS 18.0, *) {
			self.allowedWritingToolsResultOptions = [.plainText, .richText]
		}
	
		#if targetEnvironment(macCatalyst)
		let appleColorPreferencesChangedNotification = Notification.Name(rawValue: "AppleColorPreferencesChangedNotification")
		DistributedNotificationCenter.default.addObserver(self, selector: #selector(appleColorPreferencesChanged(_:)), name: appleColorPreferencesChangedNotification, object: nil)
		#else
		if #available(iOS 18.0, *) {
			self.textFormattingConfiguration = nil
		}
		#endif
		
		updateTintColor()
		
		startActivityMonitoring()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
 
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .editLink:
			return isFirstResponder
		case .toggleUnderline:
			return false
		default:
			return super.canPerformAction(action, withSender: sender)
		}
	}
    
	override func paste(_ sender: Any?) {
		if selectedRange.length > 0 && UIPasteboard.general.hasURLs, let url = UIPasteboard.general.url {
			textStorage.addAttribute(.link, value: url, range: selectedRange)
			textWasChanged()
		} else {
			super.paste(sender)
		}
	}
	
	override func editMenu(for textRange: UITextRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
		var results = [UIMenuElement]()
		
		for suggestedAction in suggestedActions {
			guard let menu = suggestedAction as? UIMenu else {
				results.append(suggestedAction)
				continue
			}
			
			guard menu.identifier != .font else { continue }
			guard menu.identifier != .spelling else { continue }
			guard menu.identifier != .substitutions else { continue }

			results.append(menu)
		}
		
		return UIMenu(children: results)
	}
	
	// MARK: API
	
	func updateTextPreferences() {
		if row?.outline?.checkSpellingWhileTyping ?? true {
			self.spellCheckingType = .yes
		} else {
			self.spellCheckingType = .no
		}
		
		if row?.outline?.correctSpellingAutomatically ?? true {
			self.autocorrectionType = .yes
		} else {
			self.autocorrectionType = .no
		}
	}
	
    func resize() {
        fatalError("resize has not been implemented")
    }
    
    func scrollIfNecessary() {
        fatalError("scrollIfNecessary has not been implemented")
    }

	func saveText() {
        guard isTextChanged else { return }
        
		// Don't save if we are in the middle of entering a multistage character, e.g Japanese
		guard markedTextRange == nil else { return }
		
        textWasChanged()
        restartActivityMonitoring()
        isTextChanged = false
	}

    func textWasChanged() {
        fatalError("textChanged has not been implemented")
    }

	func update(with row: Row) {
		fatalError("update has not been implemented")
	}
	
	func scrollEditorToVisible(rect: CGRect) {
		fatalError("scrollEditorToVisible has not been implemented")
	}
	
	func updateLink(text: String, link: String?, range: NSRange) {
        var attrs = typingAttributes
        attrs.removeValue(forKey: .link)
        let attrText = NSMutableAttributedString(string: text, attributes: attrs)
		
		textStorage.beginEditing()
        textStorage.replaceCharacters(in: range, with: attrText)

        let newRange = NSRange(location: range.location, length: attrText.length)
		if let link, let url = URL(string: link) {
			textStorage.addAttribute(.link, value: url, range: newRange)
		} else {
			if newRange.length > 0 {
				typingAttributes = attrs
				textStorage.removeAttribute(.link, range: newRange)
			}
		}
		textStorage.endEditing()

        selectedRange = NSRange(location: range.location + text.count, length: 0)
        
        processTextChanges()
	}
	
	func replaceCharacters(_ range: NSRange, withImage image: UIImage) {
		let attachment = ImageTextAttachment()
		attachment.image = image
		attachment.imageUUID = UUID().uuidString
		let imageAttrText = NSAttributedString(attachment: attachment)

		let savedTypingAttributes = typingAttributes

		textStorage.beginEditing()
		textStorage.replaceCharacters(in: range, with: imageAttrText)
		textStorage.endEditing()

		selectedRange = .init(location: range.location + imageAttrText.length, length: 0)
		typingAttributes = savedTypingAttributes

		processTextChanges()
	}
	
    // MARK: Actions
    
    @objc func editLink(_ sender: Any?) {
        fatalError("editLink has not been implemented")
    }

	@objc func insertNewline(_ sender: Any) {
		insertText("\n")
	}
	
	func handleDidChangeSelection() {
		guard let selectedTextRange, !selectedTextRange.isEmpty else {
			previousSelectedTextRange = nil
			return
		}

		defer {
			self.previousSelectedTextRange = selectedTextRange
		}

		guard let previousSelectedTextRange else {
			return
		}
		
		if compare(previousSelectedTextRange.start, to: selectedTextRange.start) == .orderedDescending {
			if let startHandleEndLocation = position(from: selectedTextRange.start, offset: 1),
			   let startHandleStartLocation = textRange(from: selectedTextRange.start, to: startHandleEndLocation) {
				let startHandleRect = firstRect(for: startHandleStartLocation)
				scrollEditorToVisible(rect: startHandleRect)
			}
		} else if compare(previousSelectedTextRange.end, to: selectedTextRange.end) == .orderedAscending {
			if let endHandleStartLocation = position(from: selectedTextRange.end, offset: -1),
			   let endHandleEndLocation = textRange(from: endHandleStartLocation, to: selectedTextRange.end) {
				let endHandleRect = firstRect(for: endHandleEndLocation)
				scrollEditorToVisible(rect: endHandleRect)
			}
		}
	}

	@objc func appleColorPreferencesChanged(_ note: Notification? = nil) {
		updateTintColor()
	}
	
}

// MARK: NSTextLayoutManagerDelegate

extension EditorRowTextView: NSTextLayoutManagerDelegate {
	nonisolated func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
		return EditorRowSearchLayoutFragment(textElement: textElement, range: textElement.elementRange)
	}
}

// MARK: UITextDropDelegate

extension EditorRowTextView: UITextDropDelegate {
	
	func textDroppableView(_ textDroppableView: UIView & UITextDroppable, willBecomeEditableForDrop drop: UITextDropRequest) -> UITextDropEditability {
		return .temporary
	}
	
	func textDroppableView(_ textDroppableView: UIView & UITextDroppable, proposalForDrop drop: UITextDropRequest) -> UITextDropProposal {
		guard !drop.dropSession.hasItemsConforming(toTypeIdentifiers: [Row.typeIdentifier]) else {
			return UITextDropProposal(operation: .forbidden)
		}

		return UITextDropProposal(operation: .copy)
	}
	
}

// MARK: Helpers

extension EditorRowTextView {
   
	func startActivityMonitoring() {
		inactivityTask = Task {
			for await _ in activityChannel.debounce(for: .seconds(5.0)) {
				if !Task.isCancelled {
					saveText()
					RequestReview.request()
				}
			}
		}
	}
	
	func stopActivityMonitoring() {
		inactivityTask?.cancel()
		inactivityTask = nil
	}
	
	func debounceActivity() {
		Task {
			await activityChannel.send(())
		}
	}
	
	func restartActivityMonitoring() {
		stopActivityMonitoring()
		startActivityMonitoring()
		debounceActivity()
	}
	
	func updateTintColor() {
		if UIColor.accentColor.isDefaultAccentColor {
			tintColor = .brightenedDefaultAccentColor
		} else {
			tintColor = .accentColor
		}
	}
	
    func findAndSelectLink() -> (String?, String?, NSRange) {
        var effectiveRange = NSRange()
		
		// If nothing is selected, we test before and after it to see if we are touching a link
        if selectedRange.length == 0 {
			if selectedRange.lowerBound > 0, let link = textStorage.attribute(.link, at: selectedRange.lowerBound - 1, effectiveRange: &effectiveRange) as? URL {
				let text = textStorage.attributedSubstring(from: effectiveRange).string
				return (link.absoluteString, text, effectiveRange)
			}
			if selectedRange.lowerBound < textStorage.length, let link = textStorage.attribute(.link, at: selectedRange.lowerBound, effectiveRange: &effectiveRange) as? URL {
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
    
    func addSearchHighlighting(isInNotes: Bool) {
        guard let coordinates = row?.searchResultCoordinates else { return }
        for element in coordinates.objectEnumerator() {
            guard let coordinate = element as? SearchResultCoordinates, coordinate.isInNotes == isInNotes else { continue }
            if coordinate.isCurrentResult {
                textStorage.addAttribute(.selectedSearchResult, value: true, range: coordinate.range)
            } else {
                textStorage.addAttribute(.searchResult, value: true, range: coordinate.range)
            }
        }
    }
    
	func processTextEditingBegin() {
		let fittingSize = sizeThatFits(CGSize(width: frame.width, height: CGFloat.greatestFiniteMagnitude))
		textViewHeight = fittingSize.height
	}
	
    func processTextEditingEnding() {
        saveText()
    }

    func processTextChanges() {
        // If we deleted to the beginning of the line, remove any residual links
        if selectedRange.location == 0 && selectedRange.length == 0 {
			typingAttributes[.link] = nil
		}
        
        isTextChanged = true

        let fittingSize = sizeThatFits(CGSize(width: frame.width, height: CGFloat.greatestFiniteMagnitude))
        if let currentHeight = textViewHeight, abs(fittingSize.height - currentHeight) > 0 {
			CursorCoordinates.updateLastKnownCoordinates()
            textViewHeight = fittingSize.height
            resize()
        }
        
        scrollIfNecessary()
		debounceActivity()
    }

}

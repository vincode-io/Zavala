//
//  EditorRowTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/7/20.
//

import UIKit
import Templeton
import RSCore

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
	
    var autosaveWorkItem: DispatchWorkItem?
    var textViewHeight: CGFloat?
    var isSavingTextUnnecessary = false

	let toggleBoldCommand = UIKeyCommand(title: AppStringAssets.boldControlLabel, action: .toggleBoldface, input: "b", modifierFlags: [.command])
	let toggleItalicsCommand = UIKeyCommand(title: AppStringAssets.italicControlLabel, action: .toggleItalics, input: "i", modifierFlags: [.command])
	let editLinkCommand = UIKeyCommand(title: AppStringAssets.linkControlLabel, action: .editLink, input: "k", modifierFlags: [.command])

	private var dropInteractionDelegate: EditorRowDropInteractionDelegate!
	private var stackedUndoManager: UndoManager?

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		let textStorage = NSTextStorage()
		let layoutManager = OutlineLayoutManager()
		textStorage.addLayoutManager(layoutManager)
		let textContainer = NSTextContainer()
		layoutManager.addTextContainer(textContainer)
		
		super.init(frame: frame, textContainer: textContainer)

		textStorage.delegate = self
		textDropDelegate = self
		
		self.dropInteractionDelegate = EditorRowDropInteractionDelegate(textView: self)
		self.addInteraction(UIDropInteraction(delegate: dropInteractionDelegate))

		// These gesture recognizers will conflict with context menu preview dragging if not removed.
		if traitCollection.userInterfaceIdiom != .mac {
			gestureRecognizers?.forEach {
				if $0.name == "dragInitiation"
					|| $0.name == "dragExclusionRelationships"
					|| $0.name == "dragFailureRelationships"
					|| $0.name == "com.apple.UIKit.clickPresentationExclusion"
					|| $0.name == "com.apple.UIKit.clickPresentationFailure"
					|| $0.name == "com.apple.UIKit.longPressClickDriverPrimary" {
					removeGestureRecognizer($0)
				}
			}
		}

		self.allowsEditingTextAttributes = true
		self.isScrollEnabled = false
		self.textContainer.lineFragmentPadding = 0
		self.textContainerInset = .zero
		self.backgroundColor = .clear
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
 
	@discardableResult
    override func resignFirstResponder() -> Bool {
		CursorCoordinates.updateLastKnownCoordinates()
        return super.resignFirstResponder()
    }
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .toggleUnderline:
			return false
		default:
			return super.canPerformAction(action, withSender: sender)
		}
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
    
    func layoutEditor() {
        fatalError("reloadRow has not been implemented")
    }
    
    func makeCursorVisibleIfNecessary() {
        fatalError("makeCursorVisibleIfNecessary has not been implemented")
    }

    // MARK: API
	
	func saveText() {
        guard isTextChanged else { return }
        
		// Don't save if we are in the middle of entering a multistage character, e.g Japanese
		guard markedTextRange == nil else { return }
		
        if isSavingTextUnnecessary {
            isSavingTextUnnecessary = false
        } else {
            textWasChanged()
        }
        
        autosaveWorkItem?.cancel()
        autosaveWorkItem = nil
        isTextChanged = false
	}

    func textWasChanged() {
        fatalError("textChanged has not been implemented")
    }

	func update(row: Row) {
		fatalError("update has not been implemented")
	}
	
	func scrollEditorToVisible(rect: CGRect) {
		fatalError("scrollEditorToVisible has not been implemented")
	}
	
	func updateLinkForCurrentSelection(text: String, link: String?, range: NSRange) {
        var attrs = typingAttributes
        attrs.removeValue(forKey: .link)
        let attrText = NSMutableAttributedString(string: text, attributes: attrs)
		
		textStorage.beginEditing()
        textStorage.replaceCharacters(in: range, with: attrText)

        let newRange = NSRange(location: range.location, length: attrText.length)
		if let link = link, let url = URL(string: link) {
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
		guard let selectedTextRange = selectedTextRange, !selectedTextRange.isEmpty else {
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

}

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

// MARK: NSTextStorageDelegate

extension EditorRowTextView: NSTextStorageDelegate {
	
	func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
		
		// If you access the typingAttributes of this UITextView while the attributedString is zero, you will crash randomly
		var newTypingAttributes: [NSAttributedString.Key : Any]
		let attributeLocation = editedRange.location - 1
		if attributeLocation > -1 {
			let attributeRange = NSRange(location: attributeLocation, length: 1)
			textStorage.ensureAttributesAreFixed(in: attributeRange)
			newTypingAttributes = textStorage.attributes(at: attributeLocation, effectiveRange: nil)
			newTypingAttributes.removeValue(forKey: .font)
		} else {
			newTypingAttributes = baseAttributes
		}

		var needsDataDetection = false
		
		textStorage.enumerateAttributes(in: editedRange, options: .longestEffectiveRangeNotRequired) { (attributes, range, _) in
			var newAttributes = attributes
			
			newAttributes.merge(newTypingAttributes) { old, new in new }
			
			for key in attributes.keys {
				
				if key == .selectedSearchResult {
					newAttributes[.backgroundColor] = UIColor.systemYellow
					if traitCollection.userInterfaceStyle == .dark {
						newAttributes[.foregroundColor] = UIColor.black
					}
				}
				
				if key == .searchResult {
					newAttributes[.backgroundColor] = UIColor.systemGray
				}
				
				if key == .underlineStyle || key == .backgroundColor {
					newAttributes[key] = nil
				}
				
				if textStorage.attributedSubstring(from: range).string == " " {
					if key == .link {
						newAttributes[key] = nil
					} else {
						needsDataDetection = true
					}
				}

				if key == .font, let oldFont = attributes[key] as? UIFont, let newFont = font {
					let charsInRange = textStorage.attributedSubstring(from: range).string
					if charsInRange.containsEmoji || charsInRange.containsSymbols {
						newAttributes[key] = oldFont.withSize(newFont.pointSize)
					} else {
						let ufd = oldFont.fontDescriptor.withFamily(newFont.familyName).withSymbolicTraits(oldFont.fontDescriptor.symbolicTraits) ?? oldFont.fontDescriptor.withFamily(newFont.familyName)
						let newFont = UIFont(descriptor: ufd, size: newFont.pointSize)
						
						if newFont.isValidFor(value: charsInRange) {
							newAttributes[key] = newFont
						} else {
							newAttributes[key] = oldFont
						}
					}
				}
				
				if key == .attachment, let nsAttachment = attributes[key] as? NSTextAttachment {
					guard !(nsAttachment is ImageTextAttachment) && !(nsAttachment is MetadataTextAttachment) else { continue }
					if let image = nsAttachment.image {
						let attachment = ImageTextAttachment(data: nil, ofType: nil)
						attachment.image = image
						attachment.imageUUID = UUID().uuidString
						newAttributes[key] = attachment
					} else if let fileContents = nsAttachment.fileWrapper?.regularFileContents {
						let attachment = ImageTextAttachment(data: fileContents, ofType: nsAttachment.fileType)
						attachment.imageUUID = UUID().uuidString
						newAttributes[key] = attachment
					}
				}
			}
			
			textStorage.setAttributes(newAttributes, range: range)
		}
		
		if needsDataDetection {
			textStorage.detectData()
		}
	}
	
}

// MARK: Helpers

extension EditorRowTextView {
        
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
		if textStorage.detectData() {
			isTextChanged = true
		}
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
            layoutEditor()
        }
        
        makeCursorVisibleIfNecessary()
        
        autosaveWorkItem?.cancel()
        autosaveWorkItem = DispatchWorkItem { [weak self] in
            self?.saveText()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: autosaveWorkItem!)
    }

}

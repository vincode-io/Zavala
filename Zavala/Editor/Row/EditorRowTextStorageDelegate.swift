//
//  Created by Maurice Parker on 6/29/24.
//

import UIKit
import VinMarkdown
import VinOutlineKit

final class EditorRowTextStorageDelegate: NSObject, NSTextStorageDelegate {
	
	private var baseAttributes = [NSAttributedString.Key : Any]()

	init(baseAttributes: [NSAttributedString.Key : Any]) {
		self.baseAttributes = baseAttributes
	}
	
	nonisolated func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
		
		// If you access the typingAttributes of this UITextView while the attributedString is zero, you will crash randomly
		var newTypingAttributes: [NSAttributedString.Key : Any]
		let attributeLocation = editedRange.location - 1
		if attributeLocation > -1 {
			let attributeRange = NSRange(location: attributeLocation, length: 1)
			textStorage.ensureAttributesAreFixed(in: attributeRange)
			newTypingAttributes = textStorage.attributes(at: attributeLocation, effectiveRange: nil)
			newTypingAttributes.removeValue(forKey: .font)
			newTypingAttributes.removeValue(forKey: .codeInline)
		} else {
			newTypingAttributes = baseAttributes
		}

		textStorage.enumerateAttributes(in: editedRange, options: .longestEffectiveRangeNotRequired) { (attributes, range, _) in
			var newAttributes = attributes
			
			newAttributes.merge(newTypingAttributes) { old, new in new }
			
			for key in attributes.keys {
				
				if key == .selectedSearchResult {
					newAttributes[.foregroundColor] = UIColor.black
				}
				
				// We don't allow underlines or background colors when pasting. Same goes for lists which are denoted by paragraph styles.
				// Background colors are preserved for inline code styling.
				if key == .underlineStyle || key == .paragraphStyle {
					newAttributes[key] = nil
				}
				if key == .backgroundColor && attributes[.codeInline] == nil {
					newAttributes[key] = nil
				}
				
				let changedString = textStorage.attributedSubstring(from: range).string
				if changedString == " " || changedString == "\n" {
					if key == .link {
						newAttributes[key] = nil
					}
				}

				if key == .font, let oldFont = attributes[key] as? UIFont, let newFont = baseAttributes[.font] as? UIFont {
					// Skip font normalization for inline code; the .codeInline handler sets the monospaced font.
					if attributes[.codeInline] == nil {
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
				}
				
				if key == .codeInline {
					if let baseFont = baseAttributes[.font] as? UIFont {
						let size = baseFont.pointSize - 2
						var monoFont = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
						if let currentFont = newAttributes[.font] as? UIFont {
							let traits = currentFont.fontDescriptor.symbolicTraits
							if let descriptor = monoFont.fontDescriptor.withSymbolicTraits(traits) {
								monoFont = UIFont(descriptor: descriptor, size: size)
							}
						}
						newAttributes[.font] = monoFont
					}
				}
				
				if key == .attachment, let nsAttachment = attributes[key] as? NSTextAttachment {
					guard !(nsAttachment is ImageTextAttachment) else { continue }
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
	}
	
}

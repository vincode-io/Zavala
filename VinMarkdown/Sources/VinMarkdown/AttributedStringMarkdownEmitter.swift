//
//  AttributedStringMarkdownEmitter.swift
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private let visualLineBreak = "\n\n"

private let linkInlineStart = "["
private let linkInlineStartDivider = "]"
private let linkInlineEndDivider = "("
private let linkInlineEnd = ")"

private let linkAutomaticStart = "<"
private let linkAutomaticEnd = ">"

private let emphasisSingleStart = "_"
private let emphasisSingleEnd = "_"

private let emphasisDoubleStart = "**"
private let emphasisDoubleEnd = "**"

private let codeInlineStart = "`"
private let codeInlineEnd = "`"

private let escapeCharacter: unichar = UInt16(("\\").utf16.first!)
private let spaceCharacter: unichar = UInt16((" ").utf16.first!)
private let tabCharacter: unichar = UInt16(("\t").utf16.first!)
private let newlineCharacter: unichar = UInt16(("\n").utf16.first!)

private let literalBackslash = "\\"
private let literalAsterisk = "*"
private let literalUnderscore = "_"

struct AttributedStringMarkdownEmitter {

	static func markdownRepresentation(of attributedString: NSAttributedString) -> String {
		var result = ""

		let cleanAttributedString = NSMutableAttributedString(attributedString: attributedString)
		cleanAttributedString.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: cleanAttributedString.length))
		cleanAttributedString.removeAttribute(.paragraphStyle, range: NSRange(location: 0, length: cleanAttributedString.length))

		let normalizedAttributedString = NSAttributedString(attributedString: cleanAttributedString)
		let normalizedString = normalizedAttributedString.string
		let normalizedNSString = normalizedString as NSString
		let normalizedLength = normalizedAttributedString.length

		var inBoldRun = false
		var inItalicRun = false
		var inCodeRun = false

		var index = 0
		while index < normalizedLength {
			var currentRange = NSRange(location: 0, length: 0)
			let currentAttributes = normalizedAttributedString.attributes(at: index, effectiveRange: &currentRange)
			let currentString = normalizedNSString.substring(with: currentRange)

			var nextAttributes: [NSAttributedString.Key: Any]? = nil
			let nextIndex = currentRange.location + currentRange.length
			if nextIndex < normalizedLength {
				nextAttributes = normalizedAttributedString.attributes(at: nextIndex, effectiveRange: nil)
			}

			if currentString.contains(visualLineBreak) {
				let components = currentString.components(separatedBy: visualLineBreak)

				var visualLineBreakOffset = 0
				var currentComponentRange = NSRange(location: currentRange.location, length: 0)
				for component in components {
					currentComponentRange.length = (component as NSString).length + visualLineBreakOffset
					emitMarkdown(
						to: &result,
						normalizedString: normalizedNSString,
						currentString: component,
						currentRange: currentComponentRange,
						currentAttributes: currentAttributes,
						nextAttributes: nextAttributes,
						inBoldRun: &inBoldRun,
						inItalicRun: &inItalicRun,
						inCodeRun: &inCodeRun
					)
					currentComponentRange.location = currentComponentRange.location + (component as NSString).length + visualLineBreakOffset
					visualLineBreakOffset = (visualLineBreak as NSString).length
				}
			} else {
				emitMarkdown(
					to: &result,
					normalizedString: normalizedNSString,
					currentString: currentString,
					currentRange: currentRange,
					currentAttributes: currentAttributes,
					nextAttributes: nextAttributes,
					inBoldRun: &inBoldRun,
					inItalicRun: &inItalicRun,
					inCodeRun: &inCodeRun
				)
			}

			index = currentRange.location + currentRange.length
		}

		return result
	}

	static func debugRepresentation(of attributedString: NSAttributedString) -> String {
		var result = ""

		attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attributes, range, _ in
			var rangeHasBold = false
			var rangeHasItalic = false
			if let font = attributes[.font] as? VinFont {
				let symbolicTraits = font.fontDescriptor.symbolicTraits
				#if canImport(UIKit)
				rangeHasBold = symbolicTraits.contains(.traitBold)
				rangeHasItalic = symbolicTraits.contains(.traitItalic)
				#elseif canImport(AppKit)
				rangeHasBold = symbolicTraits.contains(.bold)
				rangeHasItalic = symbolicTraits.contains(.italic)
				#endif
			}

			var linkString = ""
			if let link = attributes[.link] {
				if let url = link as? URL {
					linkString = "<\(url.absoluteString)>"
				} else if let string = link as? String {
					linkString = "<\(string)>"
				}
			}

			let rangeHasCode = attributes[.codeInline] != nil

			let text = (attributedString.string as NSString).substring(with: range)
			let boldChar = rangeHasBold ? "B" : " "
			let italicChar = rangeHasItalic ? "I" : " "
			let codeChar = rangeHasCode ? "C" : " "
			result += "[\(text)](\(boldChar)\(italicChar)\(codeChar))\(linkString)"
		}

		result = result.replacingOccurrences(of: "\n", with: "\\n")
		result = result.replacingOccurrences(of: "\t", with: "\\t")

		return result
	}
}

// MARK: - Private Helpers

private func hasCharacterRelative(_ string: NSString, range: NSRange, offset: Int, character: unichar) -> Bool {
	let index = Int(range.location) + offset
	if index >= 0 && index < string.length {
		return string.character(at: index) == character
	}
	return false
}

private func symbolicTraitsForAttributes(_ attributes: [NSAttributedString.Key: Any]) -> VinFontDescriptorSymbolicTraits {
	guard let font = attributes[.font] as? VinFont else {
		#if canImport(UIKit)
		return []
		#elseif canImport(AppKit)
		return VinFontDescriptorSymbolicTraits()
		#endif
	}
	return font.fontDescriptor.symbolicTraits
}

private func adjustRangeForWhitespace(_ range: NSRange, in string: NSString) -> (prefix: NSRange, text: NSRange, suffix: NSRange) {
	let emptyRange = NSRange(location: NSNotFound, length: 0)

	var startIndex = range.location
	while startIndex < string.length &&
		  (string.character(at: startIndex) == spaceCharacter ||
		   string.character(at: startIndex) == tabCharacter ||
		   string.character(at: startIndex) == newlineCharacter) {
		startIndex += 1
	}

	var endIndex = range.location + range.length - 1
	while endIndex > 0 &&
		  (string.character(at: endIndex) == spaceCharacter ||
		   string.character(at: endIndex) == tabCharacter ||
		   string.character(at: endIndex) == newlineCharacter) {
		endIndex -= 1
	}
	endIndex += 1

	if startIndex < endIndex {
		let prefixRange = NSRange(location: range.location, length: startIndex - range.location)
		let textRange = NSRange(location: startIndex, length: endIndex - startIndex)
		let suffixRange = NSRange(location: endIndex, length: range.location + range.length - endIndex)
		return (prefixRange, textRange, suffixRange)
	} else {
		return (emptyRange, range, emptyRange)
	}
}

private func addEscapesInMarkdownString(_ text: inout String, marker: String) {
	guard marker.count == 1 else { return }

	let markerChar = marker
	var nsText = text as NSString
	var scanIndex = 0

	while scanIndex < nsText.length {
		let range = nsText.range(of: markerChar, options: [], range: NSRange(location: scanIndex, length: nsText.length - scanIndex))
		guard range.length > 0 else { break }

		// Check if this is a horizontal ruler
		var isHorizontalRuler = false
		if range.location == 0 || hasCharacterRelative(nsText, range: range, offset: -1, character: newlineCharacter) {
			let remainderText = nsText.substring(from: range.location) as NSString
			var remainderRange = remainderText.range(of: "\n")
			var lineText: String
			if remainderRange.location != NSNotFound {
				lineText = remainderText.substring(to: remainderRange.location)
			} else {
				lineText = remainderText as String
				remainderRange = NSRange(location: (remainderText as String).count, length: 0)
			}
			let characterText = lineText.replacingOccurrences(of: " ", with: "")
			let checkText = characterText.replacingOccurrences(of: markerChar, with: "")
			if checkText.isEmpty && characterText.count >= 3 {
				isHorizontalRuler = true
				scanIndex = range.location + range.length + lineText.count - 1
			}
		}

		if !isHorizontalRuler {
			var insertEscape = false

			var hasPrefixSpace = true
			var hasSuffixSpace = true

			if range.location == 0 {
				hasSuffixSpace = hasCharacterRelative(nsText, range: range, offset: +1, character: spaceCharacter) ||
					hasCharacterRelative(nsText, range: range, offset: +1, character: tabCharacter) ||
					hasCharacterRelative(nsText, range: range, offset: +1, character: newlineCharacter)
			} else if range.location == nsText.length - 1 {
				hasPrefixSpace = hasCharacterRelative(nsText, range: range, offset: -1, character: spaceCharacter) ||
					hasCharacterRelative(nsText, range: range, offset: -1, character: tabCharacter) ||
					hasCharacterRelative(nsText, range: range, offset: -1, character: newlineCharacter)
			} else {
				hasPrefixSpace = hasCharacterRelative(nsText, range: range, offset: -1, character: spaceCharacter) ||
					hasCharacterRelative(nsText, range: range, offset: -1, character: tabCharacter) ||
					hasCharacterRelative(nsText, range: range, offset: -1, character: newlineCharacter)
				hasSuffixSpace = hasCharacterRelative(nsText, range: range, offset: +1, character: spaceCharacter) ||
					hasCharacterRelative(nsText, range: range, offset: +1, character: tabCharacter) ||
					hasCharacterRelative(nsText, range: range, offset: +1, character: newlineCharacter)
			}

			if !(hasPrefixSpace && hasSuffixSpace) {
				insertEscape = true
			}

			if insertEscape {
				let mutableText = NSMutableString(string: text)
				mutableText.insert(literalBackslash, at: range.location)
				text = mutableText as String
				nsText = text as NSString
				scanIndex = range.location + range.length + (literalBackslash as NSString).length
			} else {
				scanIndex = range.location + range.length
			}
		}
	}
}

private func updateMarkdownString(
	_ result: inout String,
	normalizedString: NSString,
	prefixString: String?,
	prefixRange: NSRange,
	textRange: NSRange,
	suffixString: String?,
	suffixRange: NSRange,
	needsEscaping: Bool
) {
	if prefixRange.location != NSNotFound {
		result += normalizedString.substring(with: prefixRange)
	}

	if let prefixString, !prefixString.isEmpty {
		result += prefixString
	}

	var text = normalizedString.substring(with: textRange)
	if needsEscaping {
		addEscapesInMarkdownString(&text, marker: literalBackslash)
		addEscapesInMarkdownString(&text, marker: literalAsterisk)
		addEscapesInMarkdownString(&text, marker: literalUnderscore)
	}
	result += text

	if let suffixString, !suffixString.isEmpty {
		result += suffixString
	}

	if suffixRange.location != NSNotFound {
		result += normalizedString.substring(with: suffixRange)
	}
}

private func emitMarkdown(
	to result: inout String,
	normalizedString: NSString,
	currentString: String,
	currentRange: NSRange,
	currentAttributes: [NSAttributedString.Key: Any],
	nextAttributes: [NSAttributedString.Key: Any]?,
	inBoldRun: inout Bool,
	inItalicRun: inout Bool,
	inCodeRun: inout Bool
) {
	let trimmed = currentString.trimmingCharacters(in: .whitespaces)
	if trimmed.isEmpty {
		updateMarkdownString(
			&result,
			normalizedString: normalizedString,
			prefixString: nil,
			prefixRange: NSRange(location: NSNotFound, length: 0),
			textRange: currentRange,
			suffixString: nil,
			suffixRange: NSRange(location: NSNotFound, length: 0),
			needsEscaping: false
		)
	} else {
		var currentRangeHasLink = false
		var currentRangeURL: URL? = nil

		if let linkAttribute = currentAttributes[.link] {
			var currentAttributeURL: URL? = nil
			if let url = linkAttribute as? URL {
				currentAttributeURL = url
			} else if let string = linkAttribute as? String {
				currentAttributeURL = URL(string: string)
			}
			if let currentAttributeURL {
				currentRangeHasLink = true
				if currentAttributeURL.scheme == "mailto" {
					// nil currentRangeURL indicates an automatic link
				} else {
					if currentAttributeURL.absoluteString != currentString {
						currentRangeURL = currentAttributeURL
					}
					// else nil currentRangeURL indicates an automatic link
				}
			}
		}

		var prefixString = ""
		var suffixString = ""

		let currentSymbolicTraits = symbolicTraitsForAttributes(currentAttributes)
		let nextSymbolicTraits: VinFontDescriptorSymbolicTraits
		if let nextAttributes {
			nextSymbolicTraits = symbolicTraitsForAttributes(nextAttributes)
		} else {
			#if canImport(UIKit)
			nextSymbolicTraits = []
			#elseif canImport(AppKit)
			nextSymbolicTraits = VinFontDescriptorSymbolicTraits()
			#endif
		}

		#if canImport(UIKit)
		let currentRangeHasBold = currentSymbolicTraits.contains(.traitBold)
		let currentRangeHasItalic = currentSymbolicTraits.contains(.traitItalic)
		let nextRangeHasBold = nextSymbolicTraits.contains(.traitBold)
		let nextRangeHasItalic = nextSymbolicTraits.contains(.traitItalic)
		#elseif canImport(AppKit)
		let currentRangeHasBold = currentSymbolicTraits.contains(.bold)
		let currentRangeHasItalic = currentSymbolicTraits.contains(.italic)
		let nextRangeHasBold = nextSymbolicTraits.contains(.bold)
		let nextRangeHasItalic = nextSymbolicTraits.contains(.italic)
		#endif

		let currentRangeHasCode = currentAttributes[.codeInline] != nil
		let nextRangeHasCode = nextAttributes?[.codeInline] != nil

		var needsEscaping = true

		if currentRangeHasBold {
			if !inBoldRun {
				prefixString += emphasisDoubleStart
				inBoldRun = true
			}
		}
		if currentRangeHasItalic {
			if !inItalicRun {
				prefixString += emphasisSingleStart
				inItalicRun = true
			}
		}

		if currentRangeHasCode {
			needsEscaping = false
			if !inCodeRun {
				prefixString += codeInlineStart
				inCodeRun = true
			}
		}

		if currentRangeHasLink {
			if let currentRangeURL {
				prefixString += linkInlineStart
				suffixString += linkInlineStartDivider + linkInlineEndDivider + currentRangeURL.absoluteString + linkInlineEnd
			} else {
				needsEscaping = false
				prefixString += linkAutomaticStart
				suffixString += linkAutomaticEnd
			}
		}

		if !nextRangeHasCode {
			if inCodeRun {
				suffixString += codeInlineEnd
				inCodeRun = false
			}
		}
		if !nextRangeHasItalic {
			if inItalicRun {
				suffixString += emphasisSingleEnd
				inItalicRun = false
			}
		}
		if !nextRangeHasBold {
			if inBoldRun {
				suffixString += emphasisDoubleEnd
				inBoldRun = false
			}
		}

		let (prefixRange, textRange, suffixRange) = adjustRangeForWhitespace(currentRange, in: normalizedString)
		updateMarkdownString(
			&result,
			normalizedString: normalizedString,
			prefixString: prefixString,
			prefixRange: prefixRange,
			textRange: textRange,
			suffixString: suffixString,
			suffixRange: suffixRange,
			needsEscaping: needsEscaping
		)
	}
}

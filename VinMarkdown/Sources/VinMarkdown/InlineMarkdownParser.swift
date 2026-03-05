//
//  InlineMarkdownParser.swift
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
private let emphasisSingleAlternateStart = "*"
private let emphasisSingleAlternateEnd = "*"

private let emphasisDoubleStart = "**"
private let emphasisDoubleEnd = "**"
private let emphasisDoubleAlternateStart = "__"
private let emphasisDoubleAlternateEnd = "__"

private let literalBackslash = "\\"
private let literalAsterisk = "*"
private let literalUnderscore = "_"
private let literalBacktick = "`"
private let literalCurlyBraceOpen = "{"
private let literalCurlyBraceClose = "}"
private let literalSquareBracketOpen = "["
private let literalSquareBracketClose = "]"
private let literalParenthesesOpen = "("
private let literalParenthesesClose = ")"
private let literalHashMark = "#"
private let literalPlusSign = "+"
private let literalMinusSign = "-"
private let literalDot = "."
private let literalExclamationPoint = "!"

private let escapeCharacter: unichar = UInt16(("\\").utf16.first!)
private let spaceCharacter: unichar = UInt16((" ").utf16.first!)
private let tabCharacter: unichar = UInt16(("\t").utf16.first!)
private let newlineCharacter: unichar = UInt16(("\n").utf16.first!)

private let codeInlineStart = "`"
private let codeInlineEnd = "`"

private let highlightStart = "=="
private let highlightEnd = "=="

private enum MarkdownSpanType {
	case emphasisSingle
	case emphasisDouble
	case linkInline
	case linkAutomatic
	case codeInline
	case highlight
}

struct InlineMarkdownParser {

	static let markdownLiteralCharacterSet: CharacterSet = {
		var chars = ""
		chars += literalBackslash
		chars += literalAsterisk
		chars += literalUnderscore
		chars += literalBacktick
		chars += literalCurlyBraceOpen
		chars += literalCurlyBraceClose
		chars += literalSquareBracketOpen
		chars += literalSquareBracketClose
		chars += literalParenthesesOpen
		chars += literalParenthesesClose
		chars += literalHashMark
		chars += literalPlusSign
		chars += literalMinusSign
		chars += literalDot
		chars += literalExclamationPoint
		return CharacterSet(charactersIn: chars)
	}()

	static func parse(markdown: String, baseAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
		let result = NSMutableAttributedString(string: markdown, attributes: baseAttributes)

		// Process links first (inline and automatic)
		let linkInlineDividerMarker = linkInlineStartDivider + linkInlineEndDivider
		updateAttributedString(result, beginMarker: linkInlineStart, dividerMarker: linkInlineDividerMarker, endMarker: linkInlineEnd, spanType: .linkInline)
		updateAttributedString(result, beginMarker: linkAutomaticStart, dividerMarker: nil, endMarker: linkAutomaticEnd, spanType: .linkAutomatic)

		// Process inline code (backticks) before emphasis so content inside code is not styled
		updateAttributedString(result, beginMarker: codeInlineStart, dividerMarker: nil, endMarker: codeInlineEnd, spanType: .codeInline)

		// Process highlight (==text==)
		updateAttributedString(result, beginMarker: highlightStart, dividerMarker: nil, endMarker: highlightEnd, spanType: .highlight)

		// Process double emphasis (** and __)
		updateAttributedString(result, beginMarker: emphasisDoubleStart, dividerMarker: nil, endMarker: emphasisDoubleEnd, spanType: .emphasisDouble)
		updateAttributedString(result, beginMarker: emphasisDoubleAlternateStart, dividerMarker: nil, endMarker: emphasisDoubleAlternateEnd, spanType: .emphasisDouble)

		// Process single emphasis (_ and *)
		updateAttributedString(result, beginMarker: emphasisSingleStart, dividerMarker: nil, endMarker: emphasisSingleEnd, spanType: .emphasisSingle)
		updateAttributedString(result, beginMarker: emphasisSingleAlternateStart, dividerMarker: nil, endMarker: emphasisSingleAlternateEnd, spanType: .emphasisSingle)

		// Remove backslash escapes
		removeEscapedCharacters(in: result, characterSet: markdownLiteralCharacterSet)

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

private func addTrait(_ newFontTrait: VinFontDescriptorSymbolicTraits, to result: NSMutableAttributedString, in replacementRange: NSRange) {
	result.enumerateAttribute(.font, in: replacementRange, options: []) { value, range, _ in
		guard let font = value as? VinFont else { return }

		let familyName = font.familyName
		let fontSize = font.pointSize
		let familyFontDescriptor = VinFontDescriptor(fontAttributes: [vinFamilyAttribute: familyName])

		let currentSymbolicTraits = font.fontDescriptor.symbolicTraits
		#if canImport(UIKit)
		let newSymbolicTraits = currentSymbolicTraits.union(newFontTrait)
		guard let replacementFontDescriptor = familyFontDescriptor.withSymbolicTraits(newSymbolicTraits) else { return }
		let replacementFont = VinFont(descriptor: replacementFontDescriptor, size: fontSize)
		#elseif canImport(AppKit)
		let newSymbolicTraits = currentSymbolicTraits.union(newFontTrait)
		let replacementFontDescriptor = familyFontDescriptor.withSymbolicTraits(newSymbolicTraits)
		guard let replacementFont = VinFont(descriptor: replacementFontDescriptor, size: fontSize) else { return }
		#endif

		result.removeAttribute(.font, range: range)
		result.addAttribute(.font, value: replacementFont, range: range)
	}
}

private func updateAttributedString(_ result: NSMutableAttributedString, beginMarker: String, dividerMarker: String?, endMarker: String, spanType: MarkdownSpanType) {
	let scanString = NSString(string: result.string)
	var mutationOffset = 0

	// Check for horizontal rules and ignore markers within them
	var horizontalRuleRanges = [NSRange]()
	let rulerString = String(beginMarker.prefix(1))
	if rulerString == literalAsterisk || rulerString == literalUnderscore {
		var checkRange = NSRange(location: 0, length: 1)
		while checkRange.location + checkRange.length < scanString.length {
			let lineRange = scanString.lineRange(for: checkRange)
			let lineString = scanString.substring(with: lineRange)

			let compressedString = lineString.replacingOccurrences(of: rulerString, with: "")
			let trimmedString = compressedString.trimmingCharacters(in: .whitespacesAndNewlines)
			if trimmedString.isEmpty {
				horizontalRuleRanges.append(lineRange)
			}

			checkRange = NSRange(location: lineRange.location + lineRange.length, length: 1)
		}
	}

	var abortScan = false
	var scanIndex = 0

	while !abortScan && scanIndex < scanString.length {
		let searchRange = NSRange(location: scanIndex, length: scanString.length - scanIndex)
		let beginRange = scanString.range(of: beginMarker, options: [], range: searchRange)

		guard beginRange.length > 0 else {
			abortScan = true
			continue
		}

		// Check skip conditions
		let skipEscapedMarker = hasCharacterRelative(scanString, range: beginRange, offset: -1, character: escapeCharacter)

		var skipLiteralOrListMarker = false
		if beginRange.length == 1 && spanType != .codeInline {
			let hasPrefixStartOfLine = beginRange.location == 0 || hasCharacterRelative(scanString, range: beginRange, offset: -1, character: newlineCharacter)
			let hasPrefixSpace = hasCharacterRelative(scanString, range: beginRange, offset: -1, character: spaceCharacter)
			let hasSuffixSpace = hasCharacterRelative(scanString, range: beginRange, offset: +1, character: spaceCharacter)
			let hasPrefixTab = hasCharacterRelative(scanString, range: beginRange, offset: -1, character: tabCharacter)
			let hasSuffixTab = hasCharacterRelative(scanString, range: beginRange, offset: +1, character: tabCharacter)
			if (hasPrefixStartOfLine || hasPrefixSpace || hasPrefixTab) && (hasSuffixSpace || hasSuffixTab) {
				skipLiteralOrListMarker = true
			}
		}

		var skipLinkedText = false
		var skipCodeBlock = false
		let mutatedIndex = Int(beginRange.location) - mutationOffset
		if mutatedIndex >= 0 && mutatedIndex < result.length {
			if result.attribute(.link, at: mutatedIndex, effectiveRange: nil) != nil {
				skipLinkedText = true
			}
			if result.attribute(.codeInline, at: mutatedIndex, effectiveRange: nil) != nil {
				skipCodeBlock = true
			}
		}

		var skipHorizontalRule = false
		for hrRange in horizontalRuleRanges {
			if NSLocationInRange(beginRange.location, hrRange) {
				skipHorizontalRule = true
			}
		}

		if skipEscapedMarker || skipLiteralOrListMarker || skipLinkedText || skipCodeBlock || skipHorizontalRule {
			scanIndex = beginRange.location + beginRange.length
		} else {
			let beginIndex = beginRange.location + beginRange.length

			var foundEndMarker = false
			var endRange = NSRange(location: NSNotFound, length: 0)

			var abortEndScan = false
			var scanEndIndex = beginIndex
			if scanEndIndex >= scanString.length {
				abortScan = true
			}

			while !abortEndScan && scanEndIndex < scanString.length {
				var continueScan = false

				// Look for end markers up to the first visual line break or end of text
				var remainingRange = NSRange(location: scanEndIndex, length: scanString.length - scanEndIndex)
				let visualLineRange = scanString.range(of: visualLineBreak, options: [], range: remainingRange)
				if visualLineRange.location != NSNotFound {
					remainingRange = NSRange(location: scanEndIndex, length: visualLineRange.location - scanEndIndex)
				}

				var dividerMissing = false
				if let dividerMarker {
					let dividerRange = scanString.range(of: dividerMarker, options: [], range: remainingRange)
					if dividerRange.location == NSNotFound {
						dividerMissing = true
					} else {
						let hasEscapeMarker = hasCharacterRelative(scanString, range: dividerRange, offset: -1, character: escapeCharacter)
						if hasEscapeMarker {
							dividerMissing = true
						} else {
							let newLocation = NSMaxRange(dividerRange)
							remainingRange = NSRange(location: newLocation, length: remainingRange.length - (newLocation - remainingRange.location))
						}
					}
				}

				endRange = scanString.range(of: endMarker, options: [], range: remainingRange)
				if endRange.length > 0 {
					if !dividerMissing {
						let hasEscapeMarker = hasCharacterRelative(scanString, range: endRange, offset: -1, character: escapeCharacter)
						let hasPrefixSpace = hasCharacterRelative(scanString, range: endRange, offset: -1, character: spaceCharacter)
						let hasSuffixSpace = hasCharacterRelative(scanString, range: endRange, offset: +1, character: spaceCharacter)
						if !hasEscapeMarker && (spanType == .codeInline || !(hasPrefixSpace && hasSuffixSpace)) {
							foundEndMarker = true
							break
						}
						if endRange.location + endRange.length < scanString.length {
							continueScan = true
							scanEndIndex = endRange.location + 1
						}
					}
				}

				if !continueScan {
					abortEndScan = true
					scanIndex = remainingRange.location + remainingRange.length
				}
			}

			if foundEndMarker {
				let endIndex = endRange.location

				var replaceMarkers = false
				var replacementString: String? = nil
				var replacementAttributes: [NSAttributedString.Key: Any]? = nil

				let mutatedMatchTextRange = NSRange(location: beginIndex - mutationOffset, length: endIndex - beginIndex)

				switch spanType {
				case .emphasisSingle:
					if beginIndex != endIndex {
						replaceMarkers = true
					}

				case .emphasisDouble:
					if beginIndex != endIndex {
						replaceMarkers = true
					}

				case .codeInline:
					if beginIndex != endIndex {
						replaceMarkers = true
						replacementAttributes = [.codeInline: true]
					}

				case .highlight:
					if beginIndex != endIndex {
						replaceMarkers = true
						replacementAttributes = [.textHighlightStyle: NSAttributedString.TextHighlightStyle.default]
					}

				case .linkInline:
					let matchString = (result.string as NSString).substring(with: mutatedMatchTextRange)
					let nsMatchString = matchString as NSString
					let linkTextMarkerRange = nsMatchString.range(of: linkInlineStartDivider, options: [], range: NSRange(location: 0, length: nsMatchString.length))
					if linkTextMarkerRange.length > 0 {
						let linkText = nsMatchString.substring(with: NSRange(location: 0, length: linkTextMarkerRange.location))
						let inlineLinkMarkerRange = nsMatchString.range(of: linkInlineEndDivider, options: .backwards, range: NSRange(location: 0, length: nsMatchString.length))
						if inlineLinkMarkerRange.length > 0 {
							if inlineLinkMarkerRange.location == linkTextMarkerRange.location + linkTextMarkerRange.length {
								let markerIndex = inlineLinkMarkerRange.location + 1
								let inlineLink = nsMatchString.substring(with: NSRange(location: markerIndex, length: nsMatchString.length - markerIndex))
								if let url = URL(string: inlineLink) {
									replacementString = linkText
									replacementAttributes = [.link: url]
									replaceMarkers = true
								}
							}
						}
					}

				case .linkAutomatic:
					let string = (result.string as NSString).substring(with: mutatedMatchTextRange)
					if let url = URL(string: string) {
						if url.scheme != nil {
							replacementAttributes = [.link: url]
							replaceMarkers = true
						} else {
							var synthesizedURL: URL? = nil
							let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
							if let emailRegex = try? NSRegularExpression(pattern: emailPattern, options: []),
							   emailRegex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: (string as NSString).length)) != nil,
							   NSRange(location: 0, length: (string as NSString).length) == emailRegex.rangeOfFirstMatch(in: string, options: [], range: NSRange(location: 0, length: (string as NSString).length)) {
								let mailtoString = "mailto:\(string)"
								synthesizedURL = URL(string: mailtoString)
							} else {
								let domainPattern = "[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
								if let domainRegex = try? NSRegularExpression(pattern: domainPattern, options: []),
								   domainRegex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: (string as NSString).length)) != nil,
								   NSRange(location: 0, length: (string as NSString).length) == domainRegex.rangeOfFirstMatch(in: string, options: [], range: NSRange(location: 0, length: (string as NSString).length)) {
									let httpString = "https://\(string)"
									synthesizedURL = URL(string: httpString)
								}
							}
							if let synthesizedURL {
								replacementAttributes = [.link: synthesizedURL]
								replaceMarkers = true
							}
						}
					}
				}

				if replaceMarkers {
					// Remove begin marker
					let mutatedBeginRange = NSRange(location: beginRange.location - mutationOffset, length: beginRange.length)
					result.replaceCharacters(in: mutatedBeginRange, with: "")
					mutationOffset += beginRange.length

					let mutatedTextRange = NSRange(location: beginIndex - mutationOffset, length: endIndex - beginIndex)

					// Apply traits for emphasis
					switch spanType {
					case .emphasisSingle:
						addTrait(vinItalicTrait, to: result, in: mutatedTextRange)
					case .emphasisDouble:
						addTrait(vinBoldTrait, to: result, in: mutatedTextRange)
					default:
						break
					}

					// Apply replacement attributes (for links)
					if let replacementAttributes {
						result.addAttributes(replacementAttributes, range: mutatedTextRange)
					}

					// Replace text if needed (for inline links, replace "[text](url" with "text")
					if let replacementString {
						result.replaceCharacters(in: mutatedTextRange, with: replacementString)
						mutationOffset += mutatedTextRange.length - (replacementString as NSString).length
					}

					// Remove end marker
					let mutatedEndRange = NSRange(location: endRange.location - mutationOffset, length: endRange.length)
					result.replaceCharacters(in: mutatedEndRange, with: "")
					mutationOffset += endRange.length
				}

				scanIndex = endRange.location + endRange.length
			}
		}
	}
}

private func removeEscapedCharacters(in result: NSMutableAttributedString, characterSet: CharacterSet) {
	var scanStart = 0
	var needsScan = true

	while needsScan {
		let scanString = result.string as NSString
		let range = scanString.rangeOfCharacter(from: characterSet, options: [], range: NSRange(location: scanStart, length: scanString.length - scanStart))
		if range.length > 0 {
			let hasEscapeMarker = hasCharacterRelative(scanString, range: range, offset: -1, character: escapeCharacter)
			if hasEscapeMarker {
				result.replaceCharacters(in: NSRange(location: range.location - 1, length: 1), with: "")
				scanStart = NSMaxRange(range)
				if scanStart > result.length {
					needsScan = false
				}
			} else {
				scanStart = NSMaxRange(range)
			}
		} else {
			needsScan = false
		}
	}
}

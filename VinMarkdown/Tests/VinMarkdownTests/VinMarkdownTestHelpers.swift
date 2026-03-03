//
//  VinMarkdownTestHelpers.swift
//

import Foundation
@testable import VinMarkdown

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
nonisolated(unsafe) let testFont = NSFont.systemFont(ofSize: 12.0)
nonisolated(unsafe) let testFont17 = NSFont.systemFont(ofSize: 17.0)
#elseif canImport(UIKit)
import UIKit
nonisolated(unsafe) let testFont = UIFont.systemFont(ofSize: 12.0)
nonisolated(unsafe) let testFont17 = UIFont.systemFont(ofSize: 17.0)
#endif

// MARK: - Test Helpers

func checkMarkdownToRichText(_ markdown: String, _ expected: String) -> Bool {
	let attr = NSMutableAttributedString(markdownRepresentation: markdown, attributes: [.font: testFont])
	let debug = attr.markdownDebug
	return debug == expected
}

func checkRichTextToMarkdown(_ attr: NSAttributedString, _ expected: String) -> Bool {
	return attr.markdownRepresentation == expected
}

func checkRoundTrip(_ markdown: String) -> Bool {
	let attr = NSMutableAttributedString(markdownRepresentation: markdown, attributes: [.font: testFont])
	return attr.markdownRepresentation == markdown
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
func attributedString(_ text: String, withTraits traits: NSFontDescriptor.SymbolicTraits) -> NSAttributedString {
	let font = NSFont.systemFont(ofSize: 17.0)
	let fontDescriptor = font.fontDescriptor
	let newSymbolicTraits = fontDescriptor.symbolicTraits.union(traits)
	let newFontDescriptor = fontDescriptor.withSymbolicTraits(newSymbolicTraits)
	guard let newFont = NSFont(descriptor: newFontDescriptor, size: font.pointSize) else {
		return NSAttributedString(string: text, attributes: [.font: font])
	}
	return NSAttributedString(string: text, attributes: [.font: newFont])
}

func applySymbolicTraits(_ traits: NSFontDescriptor.SymbolicTraits, to attrString: NSMutableAttributedString, range: NSRange) {
	let font = NSFont.systemFont(ofSize: 17.0)
	let fontDescriptor = font.fontDescriptor
	let newSymbolicTraits = fontDescriptor.symbolicTraits.union(traits)
	let newFontDescriptor = fontDescriptor.withSymbolicTraits(newSymbolicTraits)
	guard let newFont = NSFont(descriptor: newFontDescriptor, size: font.pointSize) else { return }
	attrString.setAttributes([.font: newFont], range: range)
}
#elseif canImport(UIKit)
func attributedString(_ text: String, withTraits traits: UIFontDescriptor.SymbolicTraits) -> NSAttributedString {
	let font = UIFont.systemFont(ofSize: 17.0)
	let fontDescriptor = font.fontDescriptor
	let newSymbolicTraits = fontDescriptor.symbolicTraits.union(traits)
	guard let newFontDescriptor = fontDescriptor.withSymbolicTraits(newSymbolicTraits) else {
		return NSAttributedString(string: text, attributes: [.font: font])
	}
	let newFont = UIFont(descriptor: newFontDescriptor, size: font.pointSize)
	return NSAttributedString(string: text, attributes: [.font: newFont])
}

func applySymbolicTraits(_ traits: UIFontDescriptor.SymbolicTraits, to attrString: NSMutableAttributedString, range: NSRange) {
	let font = UIFont.systemFont(ofSize: 17.0)
	let fontDescriptor = font.fontDescriptor
	let newSymbolicTraits = fontDescriptor.symbolicTraits.union(traits)
	guard let newFontDescriptor = fontDescriptor.withSymbolicTraits(newSymbolicTraits) else { return }
	let newFont = UIFont(descriptor: newFontDescriptor, size: font.pointSize)
	attrString.setAttributes([.font: newFont], range: range)
}
#endif

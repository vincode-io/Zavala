//
//  VinMarkdown.swift
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias VinFont = UIFont
public typealias VinFontDescriptor = UIFontDescriptor
public typealias VinFontDescriptorSymbolicTraits = UIFontDescriptor.SymbolicTraits
let vinBoldTrait = UIFontDescriptor.SymbolicTraits.traitBold
let vinItalicTrait = UIFontDescriptor.SymbolicTraits.traitItalic
let vinFamilyAttribute = UIFontDescriptor.AttributeName.family
#elseif canImport(AppKit)
import AppKit
public typealias VinFont = NSFont
public typealias VinFontDescriptor = NSFontDescriptor
public typealias VinFontDescriptorSymbolicTraits = NSFontDescriptor.SymbolicTraits
let vinBoldTrait = NSFontDescriptor.SymbolicTraits.bold
let vinItalicTrait = NSFontDescriptor.SymbolicTraits.italic
let vinFamilyAttribute = NSFontDescriptor.AttributeName.family
#endif

public extension NSAttributedString.Key {
	static let codeInline: NSAttributedString.Key = .init("io.vincode.VinMarkdown.CodeInline")
}

public extension NSAttributedString {

	var markdownRepresentation: String {
		return AttributedStringMarkdownEmitter.markdownRepresentation(of: self)
	}

	var markdownDebug: String {
		return AttributedStringMarkdownEmitter.debugRepresentation(of: self)
	}

}

public extension NSMutableAttributedString {

	convenience init(markdownRepresentation: String, attributes: [NSAttributedString.Key: Any]) {
		let parsed = InlineMarkdownParser.parse(markdown: markdownRepresentation, baseAttributes: attributes)
		self.init(attributedString: parsed)
	}

}


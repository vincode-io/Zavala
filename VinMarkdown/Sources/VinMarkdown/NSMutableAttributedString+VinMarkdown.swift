//
//  NSMutableAttributedString+VinMarkdown.swift
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension NSMutableAttributedString {

	convenience init(markdownRepresentation: String, attributes: [NSAttributedString.Key: Any]) {
		let parsed = InlineMarkdownParser.parse(markdown: markdownRepresentation, baseAttributes: attributes)
		self.init(attributedString: parsed)
	}

}

//
//  NSAttributedString+VinMarkdown.swift
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension NSAttributedString {

	var markdownRepresentation: String {
		return AttributedStringMarkdownEmitter.markdownRepresentation(of: self)
	}

	var markdownDebug: String {
		return AttributedStringMarkdownEmitter.debugRepresentation(of: self)
	}

}

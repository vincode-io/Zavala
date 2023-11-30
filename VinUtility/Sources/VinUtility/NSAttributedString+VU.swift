//
//  NSAttributedString+.swift
//  Zavala
//
//  Created by Maurice Parker on 3/16/21.
//

import Foundation

extension NSAttributedString {

    #if canImport(UIKit)
	public convenience init(linkText: String, linkURL: URL) {
		let attrString = NSMutableAttributedString(string: linkText)
		let range = NSRange(location: 0, length: attrString.length)
		attrString.addAttribute(.link, value: linkURL, range: range)
		self.init(attributedString: attrString)
	}
    #endif

	public static func isOptionalStringsEqual(lhs: NSAttributedString?, rhs: NSAttributedString?) -> Bool {
		if lhs == nil && rhs == nil {
			return true
		}
		if lhs != nil && rhs == nil {
			return false
		}
        if lhs == nil && rhs != nil {
            return false
        }
        return lhs!.isEqual(to: rhs!)
	}
	
	public func trimmingCharacters(in charSet: CharacterSet) -> NSAttributedString {
		let modifiedString = NSMutableAttributedString(attributedString: self)
	   modifiedString.trimCharacters(in: charSet)
		return NSAttributedString(attributedString: modifiedString)
	}
	
}

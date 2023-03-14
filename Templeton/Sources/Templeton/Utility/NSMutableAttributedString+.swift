//
//  NSMutableAttributedString+.swift
//  Zavala
//
//  Created by Maurice Parker on 12/20/20.
//
// https://stackoverflow.com/a/47320125

import UIKit

extension NSMutableAttributedString {
	
	public func replaceFont(with font: UIFont) {
		beginEditing()
		self.enumerateAttribute(.font, in: NSRange(location: 0, length: self.length)) { (value, range, stop) in
			if let f = value as? UIFont {
				let ufd = f.fontDescriptor.withFamily(font.familyName).withSymbolicTraits(f.fontDescriptor.symbolicTraits) ?? f.fontDescriptor.withFamily(font.familyName)
				let newFont = UIFont(descriptor: ufd, size: font.pointSize)
				removeAttribute(.font, range: range)
				addAttribute(.font, value: newFont, range: range)
			}
		}
		endEditing()
	}
	
	public func trimCharacters(in charSet: CharacterSet) {
		var range = (string as NSString).rangeOfCharacter(from: charSet as CharacterSet)
		
		// Trim leading characters from character set.
		while range.length != 0 && range.location == 0 {
			replaceCharacters(in: range, with: "")
			range = (string as NSString).rangeOfCharacter(from: charSet)
		}
		
		// Trim trailing characters from character set.
		range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
		while range.length != 0 && NSMaxRange(range) == length {
			replaceCharacters(in: range, with: "")
			range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
		}
	}
	
}

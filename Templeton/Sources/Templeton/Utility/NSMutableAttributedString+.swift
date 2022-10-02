//
//  NSMutableAttributedString+.swift
//  Zavala
//
//  Created by Maurice Parker on 12/20/20.
//
// https://stackoverflow.com/a/47320125

import UIKit

extension NSMutableAttributedString {

	@discardableResult
	public func detectData() -> Bool {
		let text = string
		guard !string.isEmpty else { return false }
		
		var changeWasMade = false
		
		let detector = NSDataDetector(dataTypes: [.url])
		detector.enumerateMatches(in: text) { (range, match) in
			switch match {
			case .url(let url), .email(_, let url):
				var effectiveRange = NSRange()
				if let link = attribute(.link, at: range.location, effectiveRange: &effectiveRange) as? URL {
					if range != effectiveRange || link != url {
						changeWasMade = true
						removeAttribute(.link, range: effectiveRange)
						addAttribute(.link, value: url, range: range)
					}
				} else {
					changeWasMade = true
					addAttribute(.link, value: url, range: range)
				}
			default:
				break
			}
		}
		
		return changeWasMade
	}
	
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
	
}

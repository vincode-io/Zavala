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
		
		let detector = NSDataDetector(dataTypes: DataDetectorType.allCases)
		detector.enumerateMatches(in: text) { result in
			let originalString = attributedSubstring(from: result.range)
			let originalAttributes = originalString.attributes(at: 0, effectiveRange: nil)

			guard let resultAttributedString = result.attributedString(withAttributes: originalAttributes) else { return }
			
			if !originalString.isEqual(to: result.attributedString) {
				deleteCharacters(in: result.range)
				insert(resultAttributedString, at: result.range.location)
				changeWasMade = true
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

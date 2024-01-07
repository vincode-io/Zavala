//
///  Created by Maurice Parker on 12/20/20.
//
// https://stackoverflow.com/a/47320125

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

extension NSMutableAttributedString {

	@discardableResult
	public func detectData() -> Bool {
		let text = string
		guard !string.isEmpty else { return false }
		
		var changeWasMade = false
		
		#if canImport(UIKit)
		let detector = NSDataDetector(dataTypes: DataDetectorType.allCases)
		detector.enumerateMatches(in: text) { result in
			let originalString = attributedSubstring(from: result.range)
			let originalAttributes = originalString.attributes(at: 0, effectiveRange: nil)

			guard let resultAttributedString = result.attributedString(withAttributes: originalAttributes) else { return }
			
			if !originalString.isEqual(to: resultAttributedString) {
				deleteCharacters(in: result.range)
				insert(resultAttributedString, at: result.range.location)
				changeWasMade = true
			}
		}
		#endif
		
		return changeWasMade
	}
	
	#if canImport(UIKit)
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
	#endif

	public func addAttributes(_ attrs: [NSAttributedString.Key : Any] = [:]) {
		addAttributes(attrs, range: NSRange(location: 0, length: length))
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

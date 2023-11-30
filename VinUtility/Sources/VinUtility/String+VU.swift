//
//  Created by Maurice Parker on 3/4/17.
//  Copyright © 2017 Vincode. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

public extension String {
	
	var containsSymbols: Bool {
		for scalar in unicodeScalars {
			switch scalar.value {
			case 0x1F600...0x1F64F, // Emoticons
				 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
				 0x1F680...0x1F6FF, // Transport and Map
				 0x2300...0x23FF,   // Misc Technical symbols
				 0x2600...0x26FF,   // Misc symbols
				 0x2700...0x27BF,   // Dingbats
				 0xFE00...0xFE0F:   // Variation Selectors
				return true
			default:
				continue
			}
		}
		return false
	}
	
	#if canImport(UIKit)
	func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
		let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
		let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
		return ceil(boundingBox.height)
	}
	
	func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
		let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
		let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
		return ceil(boundingBox.width)
	}
	#endif
	
	var queryEncoded: String? {
		return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
	}
	
	func makeSearchable() -> String {
		return trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current)
	}
	
	func searchRegEx() -> NSRegularExpression? {
		return try? NSRegularExpression(pattern: makeSearchable(), options: .caseInsensitive)
	}
	
	func trimmed() -> String? {
		let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.isEmpty {
			return nil
		}
		return trimmed
	}
	
	/// Returns the string with the special XML characters (other than single-quote) ampersand-escaped.
	///
	/// The four escaped characters are `<`, `>`, `&`, and `"`.
	var escapingXMLCharacters: String {
		var escaped = String()

		for char in self {
			switch char {
				case "&":
					escaped.append("&amp;")
				case "<":
					escaped.append("&lt;")
				case ">":
					escaped.append("&gt;")
				case "\"":
					escaped.append("&quot;")
				default:
					escaped.append(char)
			}
		}

		return escaped
	}
}

public extension String {
	var isSingleEmoji: Bool { count == 1 && containsEmoji }

	var containsEmoji: Bool { contains { $0.isEmoji } }

	var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }

	var emojiString: String { emojis.map { String($0) }.reduce("", +) }

	var emojis: [Character] { filter { $0.isEmoji } }

	var emojiScalars: [UnicodeScalar] { filter { $0.isEmoji }.flatMap { $0.unicodeScalars } }
}

//
//  Created by Maurice Parker on 3/4/17.
//  Copyright © 2017 Vincode. All rights reserved.
//
import Foundation

public extension String {
	
	init(localized: String, comment: String? = nil) {
		self = localized
	}
	
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

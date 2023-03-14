//
//  String +.swift
//  
//
//  Created by Maurice Parker on 10/9/21.
//

import Foundation

extension String {
	
	public func makeSearchable() -> String {
		return trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current)
	}
	
	public func searchRegEx() -> NSRegularExpression? {
		return try? NSRegularExpression(pattern: makeSearchable(), options: .caseInsensitive)
	}
	
	var escapingXMLCharacters: String {
		var escaped = String()

		for char in self {
			switch char {
				case "\n":
					escaped.append("&#10;")
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

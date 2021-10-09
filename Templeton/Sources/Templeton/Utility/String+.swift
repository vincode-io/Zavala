//
//  String +.swift
//  
//
//  Created by Maurice Parker on 10/9/21.
//

import Foundation

extension String {
	
	public func searchRegEx() -> NSRegularExpression? {
		let foldedText = trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current)
		return try? NSRegularExpression(pattern: foldedText, options: .caseInsensitive)
	}
	
}

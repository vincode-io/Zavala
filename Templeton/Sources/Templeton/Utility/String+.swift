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
	
}

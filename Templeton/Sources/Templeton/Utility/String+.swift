//
//  String +.swift
//  
//
//  Created by Maurice Parker on 10/9/21.
//

import Foundation

extension String {
	
	/// This is just here so that we can code as if we are using iOS 15 String localization API's.
	/// When we switch to requiring at least iOS 15, we will remove this and use the real thing.
	public init(localized: String, comment: String? = nil) {
		self = localized
	}
	
	var queryEncoded: String? {
		return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
	}
	
	public func makeSearchable() -> String {
		return trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current)
	}
	
	public func searchRegEx() -> NSRegularExpression? {
		return try? NSRegularExpression(pattern: makeSearchable(), options: .caseInsensitive)
	}
	
}

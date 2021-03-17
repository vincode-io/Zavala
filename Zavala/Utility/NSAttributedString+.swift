//
//  NSAttributedString+.swift
//  Zavala
//
//  Created by Maurice Parker on 3/16/21.
//

import Foundation

extension NSAttributedString {
	
	static func isOptionalStringsEqual(lhs: NSAttributedString?, rhs: NSAttributedString?) -> Bool {
		if lhs == nil && rhs == nil {
			return true
		}
		if lhs != nil || rhs != nil {
			return false
		}
		return lhs!.isEqual(to: rhs!)
	}
	
}

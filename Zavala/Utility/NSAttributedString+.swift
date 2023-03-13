//
//  NSAttributedString+.swift
//  Zavala
//
//  Created by Maurice Parker on 3/16/21.
//

import UIKit

extension NSAttributedString {
	
	static func isOptionalStringsEqual(lhs: NSAttributedString?, rhs: NSAttributedString?) -> Bool {
		if lhs == nil && rhs == nil {
			return true
		}
		if lhs != nil && rhs == nil {
			return false
		}
        if lhs == nil && rhs != nil {
            return false
        }
        return lhs!.isEqual(to: rhs!)
	}
	
	var width: CGFloat {
		guard let font = attribute(.font, at: 0, effectiveRange: nil) as? UIFont else { return 0 }
		return string.width(withConstrainedHeight: .greatestFiniteMagnitude, font: font)
	}
	
}

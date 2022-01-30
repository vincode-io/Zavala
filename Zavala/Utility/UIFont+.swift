//
//  UIFont+.swift
//  Zavala
//
//  Created by Maurice Parker on 1/30/22.
//

import UIKit

extension UIFont {
	
	func isValidFor(value: String) -> Bool {
		var code_point: [UniChar] = Array(value.utf16)
		var glyphs: [CGGlyph] = [0]
		return CTFontGetGlyphsForCharacters(self as CTFont, &code_point, &glyphs, glyphs.count)
	}
	
}

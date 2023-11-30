//
//  UIFont+.swift
//  Zavala
//
//  Created by Maurice Parker on 3/16/21.
//

#if canImport(UIKit)
import UIKit

extension UIFont {
	
	public func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
		guard let descriptor = self.fontDescriptor.withSymbolicTraits(traits) else {
			return self
		}
		return UIFont(descriptor: descriptor, size: 0)
	}
	
}
#endif

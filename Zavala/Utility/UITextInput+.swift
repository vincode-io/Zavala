//
//  UITextInput+.swift
//  Zavala
//
//  Created by Maurice Parker on 11/4/21.
//

import UIKit

extension UITextInput {
	
	var cursorRect: CGRect? {
		guard let caratPosition = selectedTextRange?.start else { return nil }
		return caretRect(for: caratPosition)
	}

}

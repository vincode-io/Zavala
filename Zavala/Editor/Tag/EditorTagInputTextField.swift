//
//  EditorTagInputTextField.swift
//  Zavala
//
//  Created by Maurice Parker on 1/29/21.
//

import UIKit

class EditorTagInputTextField: UITextField {

	#if targetEnvironment(macCatalyst)
	@objc(_focusRingType)
	var focusRingType: UInt {
		return 1 //NSFocusRingTypeNone
	}
	#endif
	
}

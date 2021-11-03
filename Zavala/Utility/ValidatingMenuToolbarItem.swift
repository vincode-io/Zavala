//
//  ValidatingMenuToolbarItem.swift
//  Zavala
//
//  Created by Maurice Parker on 11/3/21.
//

import UIKit

#if targetEnvironment(macCatalyst)

public class ValidatingMenuToolbarItem: NSMenuToolbarItem {

	var checkForUnavailable: ((NSMenuToolbarItem) -> Bool)?
	
	override public func validate() {
		guard let checkForUnavailable = checkForUnavailable else {
			isEnabled = false
			return
		}
		isEnabled = !checkForUnavailable(self)
	}
	
}

#endif


//
//  ValidatingMenuToolbarItem.swift
//  Zavala
//
//  Created by Maurice Parker on 11/3/21.
//

#if canImport(UIKit)

import UIKit

public class ValidatingMenuToolbarItem: NSMenuToolbarItem {

	public var checkForUnavailable: ((NSMenuToolbarItem) -> Bool)?
	
	override public func validate() {
		guard let checkForUnavailable else {
			isEnabled = false
			return
		}
		isEnabled = !checkForUnavailable(self)
	}
	
}

#endif


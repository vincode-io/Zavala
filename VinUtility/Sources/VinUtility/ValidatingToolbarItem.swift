//
//  ValidatingToolbarItem.swift
//  Zavala
//
//  Created by Maurice Parker on 11/13/20.
//

#if canImport(UIKit)
import UIKit

public class ValidatingToolbarItem: NSToolbarItem {

	public var checkForUnavailable: ((ValidatingToolbarItem) -> Bool)?
	
	override public func validate() {
		guard let checkForUnavailable else {
			isEnabled = false
			return
		}
		isEnabled = !checkForUnavailable(self)
	}
	
}

#endif

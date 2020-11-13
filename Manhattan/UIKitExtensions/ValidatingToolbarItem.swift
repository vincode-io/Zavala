//
//  ValidatingToolbarItem.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/13/20.
//

import UIKit

public class ValidatingToolbarItem: NSToolbarItem {

	var validator: (() -> Bool)?
	
	override public func validate() {
		guard let validator = validator else {
			isEnabled = false
			return
		}
		isEnabled = validator()
	}
	
}

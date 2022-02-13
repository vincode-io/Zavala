//
//  ToolbarButton.swift
//  Zavala
//
//  Created by Maurice Parker on 2/13/22.
//

import UIKit

class ToolbarButton: UIButton {
	
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		return bounds.insetBy(dx: -10, dy: -10).contains(point)
	}
	
}


//
//  FixedSizeImageView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/24/20.
//

import UIKit

class FixedSizeImageView: UIImageView {

	var dimension = 0
	
	override func sizeThatFits(_ size: CGSize) -> CGSize {
		return CGSize(width: dimension, height: dimension)
	}
}

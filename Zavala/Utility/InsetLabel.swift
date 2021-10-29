//
//  InsetLabel.swift
//  Zavala
//
//  Created by Maurice Parker on 10/28/21.
//

import UIKit

class InsetLabel: UILabel {

	var top: CGFloat
	var left: CGFloat
	var bottom: CGFloat
	var right: CGFloat
	
	init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
		self.top = top
		self.left = left
		self.bottom = bottom
		self.right = right
		super.init(frame: .zero)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func drawText(in rect: CGRect) {
		let insets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
		super.drawText(in: rect.inset(by: insets))
	}

	override var intrinsicContentSize: CGSize {
		let size = super.intrinsicContentSize
		return CGSize(width: size.width + left + right,
					  height: size.height + top + bottom)
	}
	
	override func sizeToFit() {
		let size = intrinsicContentSize
		frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: size.width, height: size.height)
	}

	override var bounds: CGRect {
		didSet {
			preferredMaxLayoutWidth = bounds.width - (left + right)
		}
	}
	
}

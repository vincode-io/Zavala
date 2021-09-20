//
//  UIImage+.swift
//  Zavala
//
//  Created by Maurice Parker on 6/29/21.
//

import UIKit

extension UIImage {
	
	func rotateImage() -> UIImage? {
		if (imageOrientation == UIImage.Orientation.up ) {
			return self
		}
		UIGraphicsBeginImageContext(size)
		draw(in: CGRect(origin: CGPoint.zero, size: size))
		let copy = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return copy
	}
	
	func symbolSizedForCatalyst(pointSize: CGFloat = 18.0, color: UIColor = .systemGray) -> UIImage {
		return applyingSymbolConfiguration(.init(pointSize: pointSize, weight: .regular, scale: .medium))!.tinted(color: color)!
	}
	
}

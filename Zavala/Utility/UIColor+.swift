//
//  UIColor+.swift
//  Zavala
//
//  Created by Maurice Parker on 3/5/21.
//

import UIKit

extension UIColor {
	func asImage() -> UIImage {
		let size = CGSize(width: 1, height: 1)
		return UIGraphicsImageRenderer(size: size).image(actions: { (context) in
			context.cgContext.setFillColor(cgColor)
			context.fill(.init(origin: .zero, size: size))
		})
	}
}

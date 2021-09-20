//
//  UIColor+.swift
//  Zavala
//
//  Created by Maurice Parker on 3/5/21.
//

import UIKit

extension UIColor {
	
	static var accentColor: UIColor {
		guard let systemHighlightColor = UserDefaults.standard.string(forKey: "AppleHighlightColor"),
			  let colorName = systemHighlightColor.components(separatedBy: " ").last else { return AppAssets.accent }
		
		guard colorName != "Graphite" else { return UIColor.systemGray }
		
		let selector = NSSelectorFromString(NSString.localizedStringWithFormat("system%@Color", colorName) as String)
		guard UIColor.responds(to: selector) else { return AppAssets.accent }
		return UIColor.perform(selector).takeUnretainedValue() as? UIColor ?? AppAssets.accent
	}
	
	func asImage() -> UIImage {
		let size = CGSize(width: 1, height: 1)
		return UIGraphicsImageRenderer(size: size).image(actions: { (context) in
			context.cgContext.setFillColor(cgColor)
			context.fill(.init(origin: .zero, size: size))
		})
	}
	
}

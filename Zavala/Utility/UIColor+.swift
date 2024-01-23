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
			  let colorName = systemHighlightColor.components(separatedBy: " ").last else { return UIColor(named: "AccentColor")! }
		
		guard colorName != "Graphite" else { return UIColor.systemGray }
		
		let selector = NSSelectorFromString(NSString.localizedStringWithFormat("system%@Color", colorName) as String)
		guard UIColor.responds(to: selector) else { return UIColor(named: "AccentColor")! }
		return UIColor.perform(selector).takeUnretainedValue() as? UIColor ?? UIColor(named: "AccentColor")!
	}
	
	func asImage(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
		return UIGraphicsImageRenderer(size: size).image(actions: { (context) in
			context.cgContext.setFillColor(cgColor)
			context.fill(.init(origin: .zero, size: size))
		})
	}
	
}

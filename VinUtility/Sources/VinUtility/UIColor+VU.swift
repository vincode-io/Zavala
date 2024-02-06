//
//  Zavala
//
//  Created by Maurice Parker on 3/5/21.
//
#if canImport(UIKit)
import UIKit

public extension UIColor {
	
	static var accentColor: UIColor {
		guard let systemHighlightColor = UserDefaults.standard.string(forKey: "AppleHighlightColor"),
			  let colorName = systemHighlightColor.components(separatedBy: " ").last else { return UIColor(named: "AccentColor")! }
		
		guard colorName != "Graphite" else { return UIColor.systemGray }
		
		let selector = NSSelectorFromString(NSString.localizedStringWithFormat("system%@Color", colorName) as String)
		guard UIColor.responds(to: selector) else { return UIColor(named: "AccentColor")! }
		return UIColor.perform(selector).takeUnretainedValue() as? UIColor ?? UIColor(named: "AccentColor")!
	}
	
	var isDefaultAccentColor: Bool {
		return self == UIColor(named: "AccentColor")!
	}
	
	func brighten(_ percent: CGFloat) -> UIColor {
		let ciColor = CIColor(cgColor: cgColor)
		
		let r = brighten(percent: percent, component: ciColor.red)
		let g = brighten(percent: percent, component: ciColor.green)
		let b = brighten(percent: percent, component: ciColor.blue)
		let a = ciColor.alpha
		
		return UIColor(ciColor: CIColor(red: r, green: g, blue: b, alpha: a))
	}
	
	func asImage(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
		return UIGraphicsImageRenderer(size: size).image(actions: { (context) in
			context.cgContext.setFillColor(cgColor)
			context.fill(.init(origin: .zero, size: size))
		})
	}
	
}

// MARK: Helpers

private extension UIColor {
	
	func brighten(percent: CGFloat, component: CGFloat) -> CGFloat {
		return ((1 - component) * percent) + component
	}
	
}

#endif

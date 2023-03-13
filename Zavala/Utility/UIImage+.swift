//
//  UIImage+.swift
//  Zavala
//
//  Created by Maurice Parker on 6/29/21.
//

import UIKit

extension UIImage {

	struct UserInfoKeys {
		static let pngData = "pngData"
	}
	
	static var appIconImage: UIImage? {
		#if targetEnvironment(macCatalyst)
		guard let icnsURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
			  let data = try? Data(contentsOf: icnsURL),
			  let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

		for i in 0..<CGImageSourceGetCount(imageSource) {
			guard let cfImageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) else {
				continue
			}
			let imageProperties = cfImageProperties as NSDictionary
			guard let width = imageProperties[kCGImagePropertyPixelWidth] as? NSNumber,
				  width.intValue > 75,
				  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else {
				continue
			}
			return UIImage(cgImage: cgImage)
		}

		return nil
		#elseif os(iOS)
		if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
			let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
			let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
			let lastIcon = iconFiles.last {
			return UIImage(named: lastIcon)
		}
		return nil
		#endif
	}

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
	
	func symbolSizedForCatalyst(pointSize: CGFloat = 16.0, color: UIColor = .systemGray) -> UIImage {
		return applyingSymbolConfiguration(.init(pointSize: pointSize, weight: .regular, scale: .medium))!.tinted(color: color)!
	}
	
}

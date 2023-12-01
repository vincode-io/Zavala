//
//  Created by Maurice Parker on 4/11/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public extension UIImage {
	
	struct UserInfoKeys {
		public static let pngData = "pngData"
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
	
	/// Tint an image.
	///
	/// - Parameter color: The color to use to tint the image.
	/// - Returns: The tinted image.
	func tinted(color: UIColor) -> UIImage? {
		let image = withRenderingMode(.alwaysTemplate)
		let imageView = UIImageView(image: image)
		imageView.tintColor = color
		
		UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
		if let context = UIGraphicsGetCurrentContext() {
			imageView.layer.render(in: context)
			let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			return tintedImage
		} else {
			return self
		}
	}
	
	/// Create a scaled image from image data.
	///
	/// - Note: the returned image may be larger than `maxPixelSize`, but not more than `maxPixelSize * 2`.
	/// - Parameters:
	///   - data: The data object containing the image data.
	///   - maxPixelSize: The maximum dimension of the image.
	static func scaleImage(_ data: Data, maxPixelSize: Int) -> CGImage? {
		
		guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
			return nil
		}
		
		let numberOfImages = CGImageSourceGetCount(imageSource)
		
		// If the image size matches exactly, then return it.
		for i in 0..<numberOfImages {
			
			guard let cfImageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) else {
				continue
			}
			
			let imageProperties = cfImageProperties as NSDictionary
			
			guard let imagePixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? NSNumber else {
				continue
			}
			if imagePixelWidth.intValue != maxPixelSize {
				continue
			}
			
			guard let imagePixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? NSNumber else {
				continue
			}
			if imagePixelHeight.intValue != maxPixelSize {
				continue
			}
			
			return CGImageSourceCreateImageAtIndex(imageSource, i, nil)
		}
		
		// If image height > maxPixelSize, but <= maxPixelSize * 2, then return it.
		for i in 0..<numberOfImages {
			
			guard let cfImageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) else {
				continue
			}
			
			let imageProperties = cfImageProperties as NSDictionary
			
			guard let imagePixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? NSNumber else {
				continue
			}
			if imagePixelWidth.intValue > maxPixelSize * 2 || imagePixelWidth.intValue < maxPixelSize {
				continue
			}
			
			guard let imagePixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? NSNumber else {
				continue
			}
			if imagePixelHeight.intValue > maxPixelSize * 2 || imagePixelHeight.intValue < maxPixelSize {
				continue
			}
			
			return CGImageSourceCreateImageAtIndex(imageSource, i, nil)
		}
		
		
		// If the image data contains a smaller image than the max size, just return it.
		for i in 0..<numberOfImages {
			
			guard let cfImageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) else {
				continue
			}
			
			let imageProperties = cfImageProperties as NSDictionary
			
			guard let imagePixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? NSNumber else {
				continue
			}
			if imagePixelWidth.intValue < 1 || imagePixelWidth.intValue > maxPixelSize {
				continue
			}
			
			guard let imagePixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? NSNumber else {
				continue
			}
			if imagePixelHeight.intValue > 0 && imagePixelHeight.intValue <= maxPixelSize {
				if let image = CGImageSourceCreateImageAtIndex(imageSource, i, nil) {
					return image
				}
			}
		}
		
		return createThumbnail(imageSource, maxPixelSize: maxPixelSize)
		
	}
	
	/// Create a thumbnail from a CGImageSource.
	///
	/// - Parameters:
	///   - imageSource: The `CGImageSource` from which to create the thumbnail.
	///   - maxPixelSize: The maximum dimension of the resulting image.
	static func createThumbnail(_ imageSource: CGImageSource, maxPixelSize: Int) -> CGImage? {
		let options = [kCGImageSourceCreateThumbnailWithTransform : true,
				   kCGImageSourceCreateThumbnailFromImageIfAbsent : true,
							  kCGImageSourceThumbnailMaxPixelSize : NSNumber(value: maxPixelSize)]
		return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
	}
	
}

#endif

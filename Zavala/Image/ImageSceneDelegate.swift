//
//  ImageSceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 11/12/21.
//

import UIKit
import Templeton

class ImageSceneDelegate: UIResponder, UIWindowSceneDelegate {

	weak var scene: UIScene?
	weak var session: UISceneSession?
	var window: UIWindow?
	var imageViewController: ImageViewController!
	
	var needsConfigureWindowSize = true
	var needsConfigureAspectRatio = true
	var initialX: Double = 0
	var initialY: Double = 0
	var initialWidth: Double = 0
	var initialHeight: Double = 0
 
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		self.scene = scene
		self.session = session
		
		guard let imageViewController = window?.rootViewController as? ImageViewController,
			  let pngData = connectionOptions.userActivities.first?.userInfo?[UIImage.UserInfoKeys.pngData] as? Data,
			  let image = UIImage(data: pngData) else {
				  UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
				  return
			  }

		self.imageViewController = imageViewController
		self.imageViewController.image = image

		#if targetEnvironment(macCatalyst)
			window?.windowScene?.titlebar?.titleVisibility = .hidden
			window?.windowScene?.titlebar?.toolbar = nil
		#endif

		window?.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: Double.zero, height: Double.zero)

		guard let screenSize = window?.windowScene?.screen.bounds.size else { return }

		let imageWidth = image.size.width
		let imageHeight = image.size.height
		let screenWidth = screenSize.width
		let screenHeight = screenSize.height

		if screenWidth > imageWidth && screenHeight > imageHeight {
			needsConfigureWindowSize = false
			initialWidth = imageWidth
			initialHeight = imageHeight

			if let windowFrame = window?.frame {
				window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: imageWidth, height: imageHeight)
			}
			
			return
		}

		let imageRatio = imageWidth / imageHeight
		let screenRatio = screenWidth / screenHeight

		if screenRatio > imageRatio {
			initialWidth = imageWidth * (screenHeight / imageHeight) // * screenScale
			initialHeight = screenHeight // * screenScale
		} else {
			initialHeight = imageHeight * (screenWidth / imageWidth)  // * screenScale
			initialWidth = screenWidth  // * screenScale
		}
		
		initialX = (screenWidth - initialWidth) / 2
		initialY = (screenHeight - initialHeight) / 2
	}

	
	func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace, interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation, traitCollection previousTraitCollection: UITraitCollection) {
		#if targetEnvironment(macCatalyst)
		if let nsWindow = window?.nsWindow, needsConfigureWindowSize {
			needsConfigureWindowSize = false
			appDelegate.appKitPlugin?.configureWindowSize(nsWindow, x: initialX, y: initialY, width: initialWidth, height: initialHeight)
		}
		if let nsWindow = window?.nsWindow, needsConfigureAspectRatio {
			needsConfigureAspectRatio = false
			appDelegate.appKitPlugin?.configureWindowAspectRatio(nsWindow, width: initialWidth, height: initialHeight)
		}
		#endif
	}
	
}

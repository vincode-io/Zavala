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

		window?.windowScene?.titlebar?.titleVisibility = .hidden
		window?.windowScene?.titlebar?.toolbar = nil

		var width = image.size.width
		var height = image.size.height

		if let screenSize = window?.windowScene?.screen.nativeBounds.size {
			if screenSize.width < width {
				width = screenSize.width
			}
			if screenSize.height < height {
				height = screenSize.height
			}
		}
		
		window?.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: Double.zero, height: Double.zero)

		if let windowFrame = window?.frame {
			window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: width, height: height)
		}
		
	}
	
}

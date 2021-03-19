//
//  MacOpenQuicklySceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 3/19/21.
//

import UIKit

import Templeton

class MacOpenQuicklySceneDelegate: UIResponder, UIWindowSceneDelegate {

	weak var scene: UIScene?
	weak var session: UISceneSession?
	var window: UIWindow?
	var macOpenQuicklyViewController: MacOpenQuicklyViewController!
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		self.scene = scene
		self.session = session
		
		guard let macOpenQuicklyViewController = window?.rootViewController as? MacOpenQuicklyViewController else {
			return
		}
		
		macOpenQuicklyViewController.sceneDelegate = self

		window?.windowScene?.sizeRestrictions?.maximumSize = CGSize(width: 500, height: 400)
		window?.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: 500, height: 400)

		if let windowFrame = window?.frame {
			window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: 500, height: 400)
		}
				
	}

	// MARK: API
	
	func closeWindow() {
		guard let session = session else { return }
		UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
	}
	
}


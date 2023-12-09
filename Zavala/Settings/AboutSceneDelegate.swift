//
//  AboutSceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 3/11/23.
//

import UIKit
import SwiftUI

class AboutSceneDelegate: UIResponder, UIWindowSceneDelegate {

	private static let windowSize = CGSize(width: 300, height: 400)
	
	weak var scene: UIScene?
	weak var session: UISceneSession?
	var window: UIWindow?
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		self.scene = scene
		self.session = session
		
		updateUserInterfaceStyle()

		#if targetEnvironment(macCatalyst)
			window?.windowScene?.titlebar?.titleVisibility = .hidden
			window?.windowScene?.titlebar?.toolbar = nil
		#endif

		window?.windowScene?.sizeRestrictions?.minimumSize = Self.windowSize
		window?.windowScene?.sizeRestrictions?.maximumSize = Self.windowSize
		
		if let windowFrame = window?.frame {
			window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: Self.windowSize.width, height: Self.windowSize.height)
		}
	}

}

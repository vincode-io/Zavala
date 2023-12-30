//
//  SettingsSceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 12/29/23.
//

import UIKit

class SettingsSceneDelegate: UIResponder, UIWindowSceneDelegate {

	private static let windowSize = CGSize(width: 400, height: 450)
	
	var userInterfaceColorPalette = AppDefaults.shared.userInterfaceColorPalette
	var window: UIWindow?
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		updateUserInterfaceStyle()

		window?.windowScene?.titlebar?.titleVisibility = .hidden
		window?.windowScene?.sizeRestrictions?.minimumSize = Self.windowSize
		window?.windowScene?.sizeRestrictions?.maximumSize = Self.windowSize
		
		if let windowFrame = window?.frame {
			window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: Self.windowSize.width, height: Self.windowSize.height)
		}

		
		NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
			if self?.userInterfaceColorPalette != AppDefaults.shared.userInterfaceColorPalette {
				self?.updateUserInterfaceStyle()
			}
		}
	}
	
}

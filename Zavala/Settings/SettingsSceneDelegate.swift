//
//  SettingsSceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 12/29/23.
//

import UIKit

class SettingsSceneDelegate: UIResponder, UIWindowSceneDelegate {

	private static let windowSize = CGSize(width: 400, height: 500)
	
	var userInterfaceColorPalette = AppDefaults.shared.userInterfaceColorPalette
	var window: UIWindow?
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		updateUserInterfaceStyle()

		#if targetEnvironment(macCatalyst)
		window?.windowScene?.titlebar?.titleVisibility = .hidden
		window?.windowScene?.title = .settingsControlLabel
		#endif
		
		window?.windowScene?.sizeRestrictions?.minimumSize = Self.windowSize
		window?.windowScene?.sizeRestrictions?.maximumSize = Self.windowSize
		
		if let windowFrame = window?.frame {
			window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: Self.windowSize.width, height: Self.windowSize.height)
		}

		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
	}

	@objc nonisolated func userDefaultsDidChange() {
		Task { @MainActor in
			if userInterfaceColorPalette != AppDefaults.shared.userInterfaceColorPalette {
				updateUserInterfaceStyle()
			}
		}
	}
}

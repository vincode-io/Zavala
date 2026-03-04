//
//  EditShortcutsMenuSceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 3/3/26.
//

import UIKit

class EditShortcutsMenuSceneDelegate: UIResponder, UIWindowSceneDelegate {

	private static let windowSize = CGSize(width: 400, height: 500)

	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		updateUserInterfaceStyle()

		#if targetEnvironment(macCatalyst)
			window?.windowScene?.titlebar?.titleVisibility = .visible
			window?.windowScene?.titlebar?.toolbar = nil
			window?.windowScene?.title = .editShortcutsMenuControlLabel
		#endif

		window?.windowScene?.sizeRestrictions?.minimumSize = Self.windowSize
		window?.windowScene?.sizeRestrictions?.maximumSize = Self.windowSize

		if let windowFrame = window?.frame {
			window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: Self.windowSize.width, height: Self.windowSize.height)
		}
	}

}

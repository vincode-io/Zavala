//
//  UIWindowSceneDelegate+.swift
//  Zavala
//
//  Created by Maurice Parker on 9/25/21.
//

import UIKit

extension UIWindowSceneDelegate {
	
	func updateUserInterfaceStyle() {
		Task { @MainActor in
			switch AppDefaults.shared.userInterfaceColorPalette {
			case .automatic:
				self.window??.overrideUserInterfaceStyle = .unspecified
			case .light:
				self.window??.overrideUserInterfaceStyle = .light
			case .dark:
				self.window??.overrideUserInterfaceStyle = .dark
			}
			
			#if targetEnvironment(macCatalyst)
			appDelegate.appKitPlugin?.updateAppearance(self.window??.nsWindow)
			#endif
		}
	}
	
}

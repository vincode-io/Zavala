//
//  SceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import Templeton

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?
	var mainSplitViewController: MainSplitViewController!
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let mainSplitViewController = window?.rootViewController as? MainSplitViewController else {
			return
		}
		self.mainSplitViewController = mainSplitViewController
		
		#if targetEnvironment(macCatalyst)
		guard let windowScene = scene as? UIWindowScene else { return }
		
		let toolbar = NSToolbar(identifier: "main")
		toolbar.delegate = mainSplitViewController
		toolbar.displayMode = .iconOnly
		
		if let titlebar = windowScene.titlebar {
			titlebar.toolbar = toolbar
			titlebar.toolbarStyle = .automatic
		}
		#endif

		mainSplitViewController.startUp()

		if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
			mainSplitViewController.handle(userActivity)
		}
		
	}

	func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
		return mainSplitViewController.stateRestorationActivity
	}
	
	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		mainSplitViewController.handle(userActivity)
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		AccountManager.shared.save()
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let url = URLContexts.first?.url else { return }
		mainSplitViewController.restoreArchive(url: url)
	}

}


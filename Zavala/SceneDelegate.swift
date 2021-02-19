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

		NotificationCenter.default.addObserver(self, selector: #selector(checkForUserDefaultsChanges), name: UserDefaults.didChangeNotification, object: nil)

		self.mainSplitViewController = mainSplitViewController
		
		#if targetEnvironment(macCatalyst)
		guard let windowScene = scene as? UIWindowScene else { return }
		
		let toolbar = NSToolbar(identifier: "main")
		toolbar.delegate = mainSplitViewController
		toolbar.displayMode = .iconOnly
		toolbar.allowsUserCustomization = true
		toolbar.autosavesConfiguration = true
		
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
	
	func sceneWillEnterForeground(_ scene: UIScene) {
		checkForUserDefaultsChanges()
	}
	
	func sceneDidEnterBackground(_ scene: UIScene) {
		AccountManager.shared.suspend()
	}

}

extension SceneDelegate {
	
	@objc private func checkForUserDefaultsChanges() {
		let localAccount = AccountManager.shared.localAccount
		
		if !AppDefaults.shared.hideLocalAccount != localAccount.isActive {
			if AppDefaults.shared.hideLocalAccount {
				localAccount.deactivate()
			} else {
				localAccount.activate()
			}
		}
		
		let cloudKitAccount = AccountManager.shared.cloudKitAccount
		
		if AppDefaults.shared.enableCloudKit && cloudKitAccount == nil {
			AccountManager.shared.createCloudKitAccount()
		} else if !AppDefaults.shared.enableCloudKit && cloudKitAccount != nil {
			AccountManager.shared.deleteCloudKitAccount()
		}
		
	}
	
}

//
//  SceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import CloudKit
import Templeton

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	weak var scene: UIScene?
	var window: UIWindow?
	var mainSplitViewController: MainSplitViewController!
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		self.scene = scene
		
		guard let mainSplitViewController = window?.rootViewController as? MainSplitViewController else {
			return
		}

		self.mainSplitViewController = mainSplitViewController
		self.mainSplitViewController.sceneDelegate = self
		
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
	
	func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith shareMetadata: CKShare.Metadata) {
		AccountManager.shared.cloudKitAccount?.userDidAcceptCloudKitShareWith(shareMetadata)
	}
	
	// MARK: API
	
	func validateToolbar() {
		#if targetEnvironment(macCatalyst)
		guard let windowScene = scene as? UIWindowScene else { return }
		windowScene.titlebar?.toolbar?.visibleItems?.forEach({ $0.validate() })
		#endif
	}
	
}

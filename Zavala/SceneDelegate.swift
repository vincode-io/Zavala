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
		
		updateUserInterfaceStyle()
		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
		
		AppDefaults.shared.lastMainWindowWasClosed = false
		
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

		// If we let the user shrink the window down too small, the collection view will crash itself with a
		// no selector found error on an internal Apple API
		windowScene.sizeRestrictions?.minimumSize = CGSize(width: 800, height: 600)
		
		#endif

		mainSplitViewController.startUp()

		if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
			mainSplitViewController.handle(userActivity, isNavigationBranch: false)
			return
		}
		
		if let url = connectionOptions.urlContexts.first?.url, let documentID = EntityID(url: url) {
			mainSplitViewController.openDocument(documentID, isNavigationBranch: false)
			return
		}
		
		if let userInfo = AppDefaults.shared.lastMainWindowState {
			mainSplitViewController.handle(userInfo, isNavigationBranch: false)
			AppDefaults.shared.lastMainWindowState = nil
		}
	}
	
	func sceneDidDisconnect(_ scene: UIScene) {
		if UIApplication.shared.applicationState == .active {
			if !UIApplication.shared.windows.contains(where: { $0.rootViewController is MainSplitViewController }) {
				AppDefaults.shared.lastMainWindowWasClosed = true
				AppDefaults.shared.lastMainWindowState = mainSplitViewController.stateRestorationActivity.userInfo
			}
		}
	}

	func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
		return mainSplitViewController.stateRestorationActivity
	}
	
	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		mainSplitViewController.handle(userActivity, isNavigationBranch: true)
	}
	
	func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
		if let url = urlContexts.first?.url, let documentID = EntityID(url: url) {
			mainSplitViewController.openDocument(documentID, isNavigationBranch: true)
			return
		}
		
		let opmlURLs = urlContexts.filter({ $0.url.pathExtension == "opml" }).map({ $0.url })
		mainSplitViewController.importOPMLs(urls: opmlURLs)
		
		#if targetEnvironment(macCatalyst)
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			appDelegate.appKitPlugin?.clearRecentDocuments()
		}
		#endif
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

private extension SceneDelegate {
	
	@objc func userDefaultsDidChange() {
		updateUserInterfaceStyle()
	}

}

//
//  SceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import UniformTypeIdentifiers
import CloudKit
import VinOutlineKit
import VinUtility

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
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitStateDidChange), name: .CloudKitSyncWillBegin, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitStateDidChange), name: .CloudKitSyncDidComplete, object: nil)

		AppDefaults.shared.lastMainWindowWasClosed = false
		
		self.mainSplitViewController = mainSplitViewController
		self.mainSplitViewController.sceneDelegate = self
		self.mainSplitViewController.showsSecondaryOnlyButton = true

		#if targetEnvironment(macCatalyst)
		guard let windowScene = scene as? UIWindowScene else { return }
		
		let toolbar = NSToolbar(identifier: "main")
		toolbar.delegate = mainSplitViewController
		toolbar.displayMode = .iconOnly
		toolbar.allowsUserCustomization = true
		toolbar.autosavesConfiguration = true
		
		if let titlebar = windowScene.titlebar {
			titlebar.titleVisibility = .hidden
			titlebar.toolbar = toolbar
			titlebar.toolbarStyle = .unified
		}

		// If we let the user shrink the window down too small, the collection view will crash itself with a
		// no selector found error on an internal Apple API
		windowScene.sizeRestrictions?.minimumSize = CGSize(width: 800, height: 600)
		
		#endif

		mainSplitViewController.startUp()
		
		if let shareMetadata = connectionOptions.cloudKitShareMetadata {
			acceptShare(shareMetadata)
			return
		}

		if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
			Task {
				await mainSplitViewController.handle(userActivity, isNavigationBranch: true)
			}
			return
		}
		
		if let url = connectionOptions.urlContexts.first?.url, let entityID = EntityID(url: url) {
			Task {
				await mainSplitViewController.handleDocument(entityID, isNavigationBranch: true)
			}
			return
		}
		
		if let userInfo = AppDefaults.shared.lastMainWindowState {
			Task {
				await mainSplitViewController.handle(userInfo, isNavigationBranch: true)
			}
			AppDefaults.shared.lastMainWindowState = nil
		}
	}
	
	func sceneDidDisconnect(_ scene: UIScene) {
		if UIApplication.shared.applicationState == .active {
			if let windows = (scene as? UIWindowScene)?.windows {
				if windows.contains(where: { $0.rootViewController is MainSplitViewController }) {
					AppDefaults.shared.lastMainWindowWasClosed = true
					AppDefaults.shared.lastMainWindowState = mainSplitViewController.stateRestorationActivity.userInfo
				}
			}
		}
	}

	func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
		return mainSplitViewController.stateRestorationActivity
	}
	
	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		Task {
			await mainSplitViewController.handle(userActivity, isNavigationBranch: true)
		}
	}
	
	func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
		if let url = urlContexts.first?.url, let entityID = EntityID(url: url) {
			Task {
				await mainSplitViewController.handleDocument(entityID, isNavigationBranch: true)
			}
			return
		}
		
		let opmlURLs = urlContexts.filter({ $0.url.pathExtension == UTType.opml.preferredFilenameExtension }).map({ $0.url })
		mainSplitViewController.importOPMLs(urls: opmlURLs)
		
		#if targetEnvironment(macCatalyst)
		Task { @MainActor in
			try? await Task.sleep(for: .seconds(1))
			appDelegate.appKitPlugin?.clearRecentDocuments()
		}
		#endif
	}
	
	func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith shareMetadata: CKShare.Metadata) {
		acceptShare(shareMetadata)
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
	
	@objc nonisolated func userDefaultsDidChange() {
		Task { @MainActor in
			updateUserInterfaceStyle()
		}
	}

	@objc func cloudKitStateDidChange() {
		validateToolbar()
	}

	func acceptShare(_ shareMetadata: CKShare.Metadata) {
		Task {
			await AccountManager.shared.cloudKitAccount?.userDidAcceptCloudKitShareWith(shareMetadata)
			if let documentID = AccountManager.shared.cloudKitAccount?.findDocument(shareRecordID: shareMetadata.share.recordID)?.id {
				await mainSplitViewController.handleDocument(documentID, isNavigationBranch: true)
			}
		}
	}
	
}

//
//  OutlineEditorSceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 3/17/21.
//

import UIKit
import CloudKit
import UniformTypeIdentifiers
import VinOutlineKit
import VinUtility

class OutlineEditorSceneDelegate: UIResponder, UIWindowSceneDelegate {

	weak var scene: UIScene?
	weak var session: UISceneSession?
	var window: UIWindow?
	var editorContainerViewController: EditorContainerViewController!
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		self.scene = scene
		self.session = session

		guard let windowScene = scene as? UIWindowScene else { return }
		
		window = UIWindow(windowScene: windowScene)
		editorContainerViewController = EditorContainerViewController()
		window!.rootViewController = editorContainerViewController
		window!.makeKeyAndVisible()
		updateUserInterfaceStyle()

		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitStateDidChange), name: .CloudKitSyncWillBegin, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitStateDidChange), name: .CloudKitSyncDidComplete, object: nil)

		editorContainerViewController.sceneDelegate = self
		
		#if targetEnvironment(macCatalyst)
		let toolbar = NSToolbar(identifier: "editor")
		toolbar.delegate = editorContainerViewController
		toolbar.displayMode = .iconOnly
		toolbar.allowsUserCustomization = true
		toolbar.autosavesConfiguration = true
		
		if let titlebar = windowScene.titlebar {
			titlebar.toolbar = toolbar
			titlebar.toolbarStyle = .unified
		}
		
		#endif

		if let shareMetadata = connectionOptions.cloudKitShareMetadata {
			acceptShare(shareMetadata)
			return
		}
		
		if let shortcutItem = connectionOptions.shortcutItem {
			handleShortcut(shortcutItem)
			return
		}
		
		if let userActivity = session.stateRestorationActivity {
			editorContainerViewController.handle(userActivity)
			return
		}

		if let userActivity = connectionOptions.userActivities.first {
			editorContainerViewController.handle(userActivity)
			if let windowFrame = window?.frame {
				window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: 700, height: 600)
			}
			return
		}
		
		if let url = connectionOptions.urlContexts.first?.url, let documentID = EntityID(url: url) {
			editorContainerViewController.editDocument(documentID)
			if let windowFrame = window?.frame {
				window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: 700, height: 600)
			}
		}
		
		closeWindow()
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openQuickly)
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
	}

	func sceneWillResignActive(_ scene: UIScene) {
		editorContainerViewController.checkPointOutline()
	}
	
	func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
		return editorContainerViewController.stateRestorationActivity
	}
	
	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		editorContainerViewController.handle(userActivity)
	}
	
	func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
		if let url = urlContexts.first?.url, let documentID = EntityID(url: url) {
		
			if let scene =  UIApplication.shared.connectedScenes.first(where: {
				(($0 as? UIWindowScene)?.keyWindow?.rootViewController as? MainCoordinator)?.selectedDocuments.first?.id == documentID
			}) {
				UIApplication.shared.requestSceneSessionActivation(scene.session, userActivity: nil, options: nil, errorHandler: nil)
			} else {
				let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
				activity.userInfo = [Pin.UserInfoKeys.pin: Pin(accountManager: appDelegate.accountManager, documentID: documentID).userInfo]
				UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
			}

			return
		}

		guard let account = appDelegate.accountManager.activeAccounts.first else { return }

		let opmlURLs = urlContexts.filter({ $0.url.pathExtension == UTType.opml.preferredFilenameExtension }).map({ $0.url })

		for url in opmlURLs {
			Task { @MainActor in
				if let document = try? await account.importOPML(url, tags: nil) {
					DocumentIndexer.updateIndex(forDocument: document)
					let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
					activity.userInfo = [Pin.UserInfoKeys.pin: Pin(accountManager: appDelegate.accountManager, document: document).userInfo]
					UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
				}
			}
		}
		#if targetEnvironment(macCatalyst)
		Task { @MainActor in
			try? await Task.sleep(for: .seconds(1))
			appDelegate.appKitPlugin?.clearRecentDocuments()
		}
		#endif
	}
	
	func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		handleShortcut(shortcutItem)
		completionHandler(true)
	}
	
	func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith shareMetadata: CKShare.Metadata) {
		acceptShare(shareMetadata)
	}
	
	// MARK: API
	
	func closeWindow() {
		guard let session else { return }
		UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
	}
	
	func validateToolbar() {
		#if targetEnvironment(macCatalyst)
		guard let windowScene = scene as? UIWindowScene else { return }
		windowScene.titlebar?.toolbar?.visibleItems?.forEach({ $0.validate() })
		#endif
	}
	
}

// MARK: Helpers

private extension OutlineEditorSceneDelegate {
	
	func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) {
		let lastPeriodIndex = shortcutItem.type.lastIndex(of: ".")!
		let startIndex = shortcutItem.type.index(after: lastPeriodIndex)
		let historyItemIndex = shortcutItem.type[startIndex..<shortcutItem.type.endIndex]
		appDelegate.openHistoryItem(index: Int(historyItemIndex)!)
	}
	
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
			await appDelegate.accountManager.cloudKitAccount?.userDidAcceptCloudKitShareWith(shareMetadata)
			if let documentID = appDelegate.accountManager.cloudKitAccount?.findDocument(shareRecordID: shareMetadata.share.recordID)?.id {
				editorContainerViewController.editDocument(documentID)
			}
		}
	}
	

}

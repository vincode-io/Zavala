//
//  OutlineEditorSceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 3/17/21.
//

import UIKit
import CloudKit
import Templeton

class OutlineEditorSceneDelegate: UIResponder, UIWindowSceneDelegate {

	weak var scene: UIScene?
	var window: UIWindow?
	var editorContainerViewController: EditorContainerViewController!
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		self.scene = scene
		
		guard let editorContainerViewController = window?.rootViewController as? EditorContainerViewController else {
			return
		}

		if let windowFrame = window?.frame {
			window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: 600, height: 600)
		}
		
		self.editorContainerViewController = editorContainerViewController
		self.editorContainerViewController.sceneDelegate = self
		
		#if targetEnvironment(macCatalyst)
		guard let windowScene = scene as? UIWindowScene else { return }
		
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

		let _ = editorContainerViewController.view
		
		if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
			editorContainerViewController.handle(userActivity)
		}
		
		if let url = connectionOptions.urlContexts.first?.url, let documentID = EntityID(url: url) {
			editorContainerViewController.openDocument(documentID)
		}
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		editorContainerViewController.shutdown()
	}
	
	func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
		return editorContainerViewController.stateRestorationActivity
	}
	
	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		editorContainerViewController.handle(userActivity)
	}
	
	func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
		if let url = urlContexts.first?.url, let documentID = EntityID(url: url) {
			editorContainerViewController.openDocument(documentID)
		}
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

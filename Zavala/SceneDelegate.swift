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
		
		guard let windowScene = scene as? UIWindowScene else { return }
		window = UIWindow(windowScene: windowScene)
		
		mainSplitViewController = MainSplitViewController(style: .tripleColumn)
		mainSplitViewController.setViewController(CollectionsViewController(collectionViewLayout: .init()), for: .primary)
		mainSplitViewController.setViewController(DocumentsViewController(collectionViewLayout: .init()), for: .supplementary)
		mainSplitViewController.setViewController(EditorViewController(), for: .secondary)
		window!.rootViewController = mainSplitViewController
		
		window!.makeKeyAndVisible()
		
		updateUserInterfaceStyle()
		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitStateDidChange), name: .CloudKitSyncWillBegin, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitStateDidChange), name: .CloudKitSyncDidComplete, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(pendingWebImportsAvailable), name: .PendingWebImportsAvailable, object: nil)

		AppDefaults.shared.lastMainWindowWasClosed = false
		
		mainSplitViewController.sceneDelegate = self
		mainSplitViewController.showsSecondaryOnlyButton = true

		#if targetEnvironment(macCatalyst)
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
		windowScene.sizeRestrictions?.minimumSize = CGSize(width: 900, height: 600)
		
		#endif

		mainSplitViewController.startUp()
		
		if let shareMetadata = connectionOptions.cloudKitShareMetadata {
			acceptShare(shareMetadata)
			return
		}

		if let shortcutItem = connectionOptions.shortcutItem {
			handleShortcut(shortcutItem)
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
	}
	
	func sceneWillResignActive(_ scene: UIScene) {
		mainSplitViewController.checkPointOutline()
		mainSplitViewController.showLockedContentScreen()
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		mainSplitViewController.removeLockedContentScreen()
		importPendingWebPages()
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		if UIApplication.shared.applicationState == .active {
			if let windows = (scene as? UIWindowScene)?.windows {
				if windows.contains(where: { $0.rootViewController is MainSplitViewController }) {
					AppDefaults.shared.lastMainWindowWasClosed = true
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
		if let url = urlContexts.first?.url, url.host == "x-callback-url" {
			appDelegate.shortcutRunner.handleCallbackURL(url)
			return
		}

		if let url = urlContexts.first?.url, let entityID = EntityID(url: url) {
			Task {
				await mainSplitViewController.handleDocument(entityID, isNavigationBranch: true)
			}
			return
		}
		
		let markdownURLs = urlContexts.filter({ $0.url.pathExtension == "md" || $0.url.pathExtension == "markdown" }).map({ $0.url })
		if !markdownURLs.isEmpty {
			mainSplitViewController.importMarkdowns(urls: markdownURLs)
		}

		let opmlURLs = urlContexts.filter({ $0.url.pathExtension == "opml" || $0.url.pathExtension == "xml" }).map({ $0.url })
		if !opmlURLs.isEmpty {
			mainSplitViewController.importOPMLs(urls: opmlURLs)
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
	
	func validateToolbar() {
		#if targetEnvironment(macCatalyst)
		guard let windowScene = scene as? UIWindowScene else { return }
		windowScene.titlebar?.toolbar?.visibleItems?.forEach({ $0.validate() })
		#endif
	}
	
}

// MARK: Helpers

private extension SceneDelegate {
	
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

	@objc func pendingWebImportsAvailable() {
		importPendingWebPages()
	}

	func acceptShare(_ shareMetadata: CKShare.Metadata) {
		Task {
			await appDelegate.accountManager.cloudKitAccount?.userDidAcceptCloudKitShareWith(shareMetadata)
			if let documentID = appDelegate.accountManager.cloudKitAccount?.findDocument(shareRecordID: shareMetadata.share.recordID)?.id {
				await mainSplitViewController.handleDocument(documentID, isNavigationBranch: true)
			}
		}
	}

	/// Imports any web page URLs the Share extension left in the shared app group queue.
	func importPendingWebPages() {
		let urls = PendingWebImportStore.drain()
		guard !urls.isEmpty else { return }
		mainSplitViewController.importWebPages(urls: urls)
	}

}

/// Reads (and clears) the queue of web page URLs the Share extension writes to the shared app group
/// container, using NSFileCoordinator for safe cross-process access. The extension owns the write
/// side (`SharedWebImportQueue.enqueue`); the file name, location, and JSON format must stay in sync
/// between the two.
private enum PendingWebImportStore {

	private static let queueFileName = "PendingWebImports.json"

	private static var queueFileURL: URL? {
		guard let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String,
			  let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
			return nil
		}
		return containerURL.appendingPathComponent(queueFileName)
	}

	/// Reads all queued URLs and clears the file using a coordinated write.
	static func drain() -> [URL] {
		guard let fileURL = queueFileURL,
			  FileManager.default.fileExists(atPath: fileURL.path) else {
			return []
		}

		var result = [URL]()
		let coordinator = NSFileCoordinator()
		var coordinatorError: NSError?

		coordinator.coordinate(writingItemAt: fileURL, options: .forDeleting, error: &coordinatorError) { actualURL in
			if let data = try? Data(contentsOf: actualURL),
			   let decoded = try? JSONDecoder().decode([String].self, from: data) {
				result = decoded.compactMap { URL(string: $0) }
			}
			if !result.isEmpty {
				try? Data("[]".utf8).write(to: actualURL, options: .atomic)
			}
		}

		return result
	}

}

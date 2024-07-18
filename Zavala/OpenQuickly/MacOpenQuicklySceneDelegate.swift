//
//  MacOpenQuicklySceneDelegate.swift
//  Zavala
//
//  Created by Maurice Parker on 3/19/21.
//

import UIKit
import VinOutlineKit

class MacOpenQuicklySceneDelegate: UIResponder, UIWindowSceneDelegate {

	weak var scene: UIScene?
	weak var session: UISceneSession?
	var window: UIWindow?
	var macOpenQuicklyViewController: MacOpenQuicklyViewController!
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		self.scene = scene
		self.session = session
		
		guard let macOpenQuicklyViewController = window?.rootViewController as? MacOpenQuicklyViewController else {
			return
		}

		updateUserInterfaceStyle()
		NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
		
		macOpenQuicklyViewController.sceneDelegate = self

		window?.windowScene?.sizeRestrictions?.maximumSize = CGSize(width: 500, height: 400)
		window?.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: 500, height: 400)

		if let windowFrame = window?.frame {
			window?.frame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: 500, height: 400)
		}
		
		if let url = connectionOptions.urlContexts.first?.url, let documentID = EntityID(url: url) {
			closeWindow()
			let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
			activity.userInfo = [Pin.UserInfoKeys.pin: Pin(documentID: documentID).userInfo]
			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
		}
	}

	func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
		closeWindow()
		if let url = urlContexts.first?.url, let documentID = EntityID(url: url) {
			let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
			activity.userInfo = [Pin.UserInfoKeys.pin: Pin(documentID: documentID).userInfo]
			UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
		}
	}

	// MARK: API
	
	func closeWindow() {
		guard let session else { return }
		UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
	}

}

private extension MacOpenQuicklySceneDelegate {
	
	@objc nonisolated func userDefaultsDidChange() {
		Task { @MainActor in
			updateUserInterfaceStyle()
		}
	}

}

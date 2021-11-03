//
//  ShowOutlineIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/8/21.
//

import UIKit
import Intents
import Templeton

public class ShowOutlineIntentHandler: NSObject, ShowOutlineIntentHandling {
	
	private weak var mainCoordinator: MainCoordinator?
	
	init(mainCoordinator: MainCoordinator?) {
		self.mainCoordinator = mainCoordinator
	}
	
	public func handle(intent: ShowOutlineIntent, completion: @escaping (ShowOutlineIntentResponse) -> Void) {
		guard let documentID = intent.outline?.entityID?.toEntityID() else {
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		if let mainSplitViewController = mainCoordinator as? MainSplitViewController {
			mainSplitViewController.openDocument(documentID)
			
			#if targetEnvironment(macCatalyst)
			appDelegate.appKitPlugin?.activateIgnoringOtherApps()
			#endif
			
			completion(.init(code: .success, userActivity: nil))
			return
		}
		
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
		activity.userInfo = [UserInfoKeys.pin: Pin(documentID: documentID).userInfo]
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
		
		#if targetEnvironment(macCatalyst)
		appDelegate.appKitPlugin?.activateIgnoringOtherApps()
		#endif

		completion(.init(code: .success, userActivity: nil))
	}
	
}

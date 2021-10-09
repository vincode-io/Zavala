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
		guard let description = intent.outline?.identifier, let documentID = EntityID(description: description) else {
			completion(.init(code: .failure, userActivity: nil))
			return
		}
		
		if let mainSplitViewController = mainCoordinator as? MainSplitViewController {
			mainSplitViewController.openDocument(documentID)
			completion(.init(code: .success, userActivity: nil))
			return
		}
		
		let activity = NSUserActivity(activityType: NSUserActivity.ActivityType.openEditor)
		activity.userInfo = [UserInfoKeys.documentID: documentID.userInfo]
		UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
		completion(.init(code: .success, userActivity: nil))
	}
	
}

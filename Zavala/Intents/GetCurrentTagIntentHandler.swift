//
//  GetCurrentTagIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents

public class GetCurrentTagIntentHandler: NSObject, GetCurrentTagIntentHandling {
	
	private weak var mainCoordinator: MainCoordinator?
	
	init(mainCoordinator: MainCoordinator?) {
		self.mainCoordinator = mainCoordinator
	}
	
	public func handle(intent: GetCurrentTagIntent, completion: @escaping (GetCurrentTagIntentResponse) -> Void) {
		let response = GetCurrentTagIntentResponse(code: .success, userActivity: nil)
		response.tagName = mainCoordinator?.currentTag?.name
		completion(response)
	}

}

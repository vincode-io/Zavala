//
//  GetCurrentTagIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import Templeton

public class GetCurrentTagsIntentHandler: NSObject, GetCurrentTagsIntentHandling {
	
	private weak var mainCoordinator: MainCoordinator?
	
	init(mainCoordinator: MainCoordinator?) {
		self.mainCoordinator = mainCoordinator
	}
	
	public func handle(intent: GetCurrentTagsIntent, completion: @escaping (GetCurrentTagsIntentResponse) -> Void) {
		let response = GetCurrentTagsIntentResponse(code: .success, userActivity: nil)
        response.tagNames = (mainCoordinator as? MainSplitViewController)?.selectedTags?.map { $0.name }
		completion(response)
	}

}

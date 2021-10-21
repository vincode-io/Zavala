//
//  GetCurrentOutlineIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 9/28/21.
//

import Intents

public class GetCurrentOutlineIntentHandler: NSObject, GetCurrentOutlineIntentHandling {
	
	private weak var mainCoordinator: MainCoordinator?
	
	init(mainCoordinator: MainCoordinator?) {
		self.mainCoordinator = mainCoordinator
	}
	
	public func handle(intent: GetCurrentOutlineIntent, completion: @escaping (GetCurrentOutlineIntentResponse) -> Void) {
		guard let outline = mainCoordinator?.currentOutline else {
			completion(GetCurrentOutlineIntentResponse(code: .notFound, userActivity: nil))
			return
		}
		
		let response = GetCurrentOutlineIntentResponse(code: .success, userActivity: nil)
		response.outlineEntityID = IntentEntityID(entityID: outline.id)
		completion(response)
	}
		
}

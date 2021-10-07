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
		let intentOutline = IntentOutline(identifier: outline.id.description, display: outline.title ?? "")
		intentOutline.url = outline.id.url
		response.outline = intentOutline
		completion(response)
	}
		
}

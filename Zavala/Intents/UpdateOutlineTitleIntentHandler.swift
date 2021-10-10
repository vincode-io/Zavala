//
//  UpdateOutlineTitleIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import Templeton

class UpdateOutlineTitleIntentHandler: NSObject, ZavalaIntentHandler, UpdateOutlineTitleIntentHandling {
	
	func resolveTitle(for intent: UpdateOutlineTitleIntent, with completion: @escaping (UpdateOutlineTitleTitleResolutionResult) -> Void) {
		guard let title = intent.title else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: title))
	}
	
	func handle(intent: UpdateOutlineTitleIntent, completion: @escaping (UpdateOutlineTitleIntentResponse) -> Void) {
		resume()
		
		guard let outline = findOutline(intent.outline) else {
			suspend()
			completion(UpdateOutlineTitleIntentResponse(code: .failure, userActivity: nil))
			return
		}
		
		outline.update(title: intent.title ?? "")
		
		suspend()
		
		let response = UpdateOutlineTitleIntentResponse(code: .success, userActivity: nil)
		response.outline = IntentOutline(outline: outline)
		completion(response)
	}
	
}

//
//  SetOutlineTitleIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import Templeton

class SetOutlineTitleIntentHandler: NSObject, ZavalaIntentHandler, SetOutlineTitleIntentHandling {
	
	func resolveTitle(for intent: SetOutlineTitleIntent, with completion: @escaping (SetOutlineTitleTitleResolutionResult) -> Void) {
		guard let title = intent.title else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: title))
	}
	
	func handle(intent: SetOutlineTitleIntent, completion: @escaping (SetOutlineTitleIntentResponse) -> Void) {
		resume()
		
		guard let outline = findOutline(intent.outlineEntityID) else {
			suspend()
			completion(SetOutlineTitleIntentResponse(code: .failure, userActivity: nil))
			return
		}
		
		outline.update(title: intent.title ?? "")
		
		suspend()
		
		completion(SetOutlineTitleIntentResponse(code: .success, userActivity: nil))
	}
	
}

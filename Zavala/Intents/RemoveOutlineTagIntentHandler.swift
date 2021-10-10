//
//  RemoveOutlineTagIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import Templeton

class RemoveOutlineTagIntentHandler: NSObject, ZavalaIntentHandler, RemoveOutlineTagIntentHandling {

	func resolveTagName(for intent: RemoveOutlineTagIntent, with completion: @escaping (RemoveOutlineTagTagNameResolutionResult) -> Void) {
		guard let tagName = intent.tagName else {
			completion(.unsupported(forReason: .required))
			return
		}
		completion(.success(with: tagName))
	}
	
	func handle(intent: RemoveOutlineTagIntent, completion: @escaping (RemoveOutlineTagIntentResponse) -> Void) {
		resume()
		
		guard let outline = findOutline(intent.outline), let tagName = intent.tagName, let account = outline.account else {
			suspend()
			completion(RemoveOutlineTagIntentResponse(code: .failure, userActivity: nil))
			return
		}
		
		if let tag = account.findTag(name: tagName) {
			outline.deleteTag(tag)
			account.deleteTag(tag)
		}
		
		suspend()
		
		let response = RemoveOutlineTagIntentResponse(code: .success, userActivity: nil)
		response.outline = IntentOutline(outline: outline)
		completion(response)
	}

}

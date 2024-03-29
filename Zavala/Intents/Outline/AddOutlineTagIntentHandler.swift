//
//  AddOutlineTagIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import VinOutlineKit

class AddOutlineTagIntentHandler: NSObject, ZavalaIntentHandler, AddOutlineTagIntentHandling {

	func resolveTagName(for intent: AddOutlineTagIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
		guard let tagName = intent.tagName else {
			completion(.needsValue())
			return
		}
		completion(.success(with: tagName))
	}
	
	func handle(intent: AddOutlineTagIntent, completion: @escaping (AddOutlineTagIntentResponse) -> Void) {
		resume()
		
		guard let outline = findOutline(intent.outline),
			  let tagName = intent.tagName,
			  let tag = outline.account?.createTag(name: tagName) else {
				  suspend()
				  completion(.init(code: .success, userActivity: nil))
				  return
			  }
		
		outline.createTag(tag)
		
		suspend()
		
		completion(.init(code: .success, userActivity: nil))
	}
	
}

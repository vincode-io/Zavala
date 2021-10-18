//
//  RemoveOutlineIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import Templeton

class RemoveOutlineIntentHandler: NSObject, ZavalaIntentHandler, RemoveOutlineIntentHandling {

	func handle(intent: RemoveOutlineIntent, completion: @escaping (RemoveOutlineIntentResponse) -> Void) {
		resume()

		guard let outline = findOutline(intent.outlineEntityID) else {
			suspend()
			completion(.init(code: .success, userActivity: nil))
			return
		}
		
		outline.account?.deleteDocument(.outline(outline))
		
		suspend()
		completion(.init(code: .success, userActivity: nil))
	}
	
}

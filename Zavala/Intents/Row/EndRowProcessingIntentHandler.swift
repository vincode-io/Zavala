//
//  EndRowProcessingIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import Templeton

class EndRowProcessingIntentHandler: NSObject, ZavalaIntentHandler, EndRowProcessingIntentHandling {

	func handle(intent: EndRowProcessingIntent, completion: @escaping (EndRowProcessingIntentResponse) -> Void) {
		guard let outline = findOutline(intent.outlineEntityID) else {
			suspend()
			completion(EndRowProcessingIntentResponse(code: .failure, userActivity: nil))
			return
		}
		
		outline.forceSave()
		outline.unload()
		suspend()
		
		completion(EndRowProcessingIntentResponse(code: .success, userActivity: nil))
	}
	
}

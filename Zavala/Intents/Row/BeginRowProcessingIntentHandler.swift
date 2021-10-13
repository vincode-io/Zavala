//
//  BeginRowProcessingIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/10/21.
//

import Intents
import Templeton

class BeginRowProcessingIntentHandler: NSObject, ZavalaIntentHandler, BeginRowProcessingIntentHandling {

	func handle(intent: BeginRowProcessingIntent, completion: @escaping (BeginRowProcessingIntentResponse) -> Void) {
		resume()
		
		guard let outline = findOutline(intent.outlineEntityID) else {
			suspend()
			completion(BeginRowProcessingIntentResponse(code: .failure, userActivity: nil))
			return
		}
		
		outline.load()
		
		completion(BeginRowProcessingIntentResponse(code: .success, userActivity: nil))
	}
	
}

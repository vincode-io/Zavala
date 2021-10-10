//
//  ZavalaIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/7/21.
//

import UIKit
import Intents
import Templeton

protocol ZavalaIntentHandler {
	
}

extension ZavalaIntentHandler {
	
	func resume() {
		if UIApplication.shared.applicationState == .background {
			AccountManager.shared.resume()
		}
	}
	
	func suspend() {
		if UIApplication.shared.applicationState == .background {
			AccountManager.shared.suspend()
		}
	}
	
	func findOutline(_ intentOutline: IntentOutline?) -> Outline? {
		guard let searchOutline = intentOutline,
			  let outlineIdentifier = searchOutline.identifier,
			  let id = EntityID(description: outlineIdentifier),
			  let outline = AccountManager.shared.findDocument(id)?.outline else {
				  return nil
			  }
		return outline
	}
}

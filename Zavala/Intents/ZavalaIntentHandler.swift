//
//  ZavalaIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/7/21.
//

import UIKit
import Intents
import VinOutlineKit

protocol ZavalaIntentHandler {
	
}

extension ZavalaIntentHandler {
	
	func resume() {
		Task { @MainActor in
			if UIApplication.shared.applicationState == .background {
				AccountManager.shared.resume()
			}
		}
	}
	
	func suspend() {
		Task { @MainActor in
			if UIApplication.shared.applicationState == .background {
				AccountManager.shared.suspend()
			}
		}
	}

	func findOutline(_ intentOutline: IntentOutline?) -> Outline? {
		return findOutline(intentOutline?.entityID)
	}
	
	func findOutline(_ intentEntityID: IntentEntityID?) -> Outline? {
		guard let description = intentEntityID?.identifier,
			  let id = EntityID(description: description),
			  let outline = AccountManager.shared.findDocument(id)?.outline else {
				  return nil
			  }
		return outline
	}
}
